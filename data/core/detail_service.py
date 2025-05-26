import json
import logging
import threading
import time
import concurrent.futures
import requests
import queue
from typing import Dict, Optional, Any, List, Set
from confluent_kafka import Consumer, Producer, KafkaException
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from models.common.api_client import fetch_lost_item_detail
from models.response.lost_item_response import parse_detail
from core.kafka_producer import send_to_kafka
from utils.concurrency import ThreadPoolManager, run_in_thread_pool
from config.config import (
    KAFKA_BOOTSTRAP_SERVERS, 
    KAFKA_TOPIC_ID, 
    KAFKA_TOPIC_SUMMARY, 
    KAFKA_TOPIC_DETAIL,
    API_THREAD_POOL_SIZE
)

logger = logging.getLogger(__name__)

# 데이터 지연 도착을 고려한 설정
SUMMARY_CACHE_RETENTION = 18000  # 요약 데이터를 1시간 동안 보관 (초 단위)
PROCESSING_START_DELAY = 120     # 초기 처리 시작 전 대기 시간 (초)
BATCH_PROCESSING_INTERVAL = 10  # 배치 처리 간격 (초)

# 처리 시간 초과 제한 (초) - 60초로 감소 (API 타임아웃 문제 해결)
PROCESSING_TIMEOUT = 60

# 최대 동시 처리 항목 수 제한
MAX_PROCESSING_ITEMS = 20  
MAX_BATCH_PROCESS = 5      # 배치 처리시 한 번에 처리할 최대 메시지 수

# API 요청 타임아웃 (초)
API_TIMEOUT = 30

# API 호출 속도 제한 관련 설정
API_CALL_INTERVAL = 1.0        # API 호출 사이의 최소 간격 (초)

# 더 적극적인 정리를 위한 설정
CLEANUP_INTERVAL = 5  # 5초마다 정리 실행

# API 요청 큐와 워커 스레드 설정
api_request_queue = queue.Queue()
api_worker_stop_event = threading.Event()

# 메시지 캐시: management_id를 키로 사용
class DataCache:
    """스레드 안전한 데이터 캐시 클래스 (지연 도착 데이터 지원)"""
    def __init__(self, name: str, max_size: int = 500000, retention_seconds: int = None):
        self.name = name
        self.cache = {}
        self.lock = threading.Lock()
        self.max_size = max_size
        self.access_times = {}  # LRU 구현을 위한 접근 시간 기록
        self.creation_times = {}  # 항목 생성 시간 기록 (보존 기간 관리용)
        self.retention_seconds = retention_seconds  # 항목 보존 기간 (None이면 LRU만 사용)
        self.stats = {
            "total_added": 0,
            "total_removed": 0,
            "total_retrieved": 0,
            "cache_hits": 0,
            "cache_misses": 0,
            "expired_items": 0
        }
    
    def get(self, key: str) -> Optional[Dict[str, Any]]:
        """키에 해당하는 데이터 조회"""
        with self.lock:
            if key in self.cache:
                self.access_times[key] = time.time()
                self.stats["total_retrieved"] += 1
                self.stats["cache_hits"] += 1
                return self.cache[key]
            self.stats["cache_misses"] += 1
            return None
    
    def put(self, key: str, value: Dict[str, Any]) -> None:
        """데이터 저장, 캐시 크기 초과 시 LRU 정책으로 오래된 항목 제거"""
        with self.lock:
            # 캐시 크기 제한 확인
            if len(self.cache) >= self.max_size and key not in self.cache:
                # LRU 정책에 따라 가장 오래 접근하지 않은 항목 제거
                if self.access_times:  # 빈 딕셔너리가 아닌 경우에만 진행
                    oldest_key = min(self.access_times, key=self.access_times.get)
                    del self.cache[oldest_key]
                    del self.access_times[oldest_key]
                    if oldest_key in self.creation_times:
                        del self.creation_times[oldest_key]
                    self.stats["total_removed"] += 1
                    logger.debug(f"{self.name} 캐시에서 LRU 항목 제거: {oldest_key}")
            
            # 새 항목 추가 또는 기존 항목 업데이트
            self.cache[key] = value
            current_time = time.time()
            self.access_times[key] = current_time
            
            # 새 항목인 경우에만 생성 시간 설정
            if key not in self.creation_times:
                self.creation_times[key] = current_time
                
            self.stats["total_added"] += 1
    
    def remove(self, key: str) -> None:
        """키에 해당하는 데이터 제거"""
        with self.lock:
            if key in self.cache:
                del self.cache[key]
                self.stats["total_removed"] += 1
            if key in self.access_times:
                del self.access_times[key]
            if key in self.creation_times:
                del self.creation_times[key]
    
    def cleanup_expired(self) -> int:
        """retention_seconds보다 오래된 항목 제거"""
        if not self.retention_seconds:
            return 0  # 보존 기간이 설정되지 않은 경우 정리하지 않음
        
        current_time = time.time()
        removed_count = 0
        
        with self.lock:
            # 유효 기간이 지난 항목 찾기
            expired_keys = [
                key for key, create_time in self.creation_times.items()
                if current_time - create_time > self.retention_seconds
            ]
            
            # 만료된 항목 제거
            for key in expired_keys:
                del self.cache[key]
                if key in self.access_times:
                    del self.access_times[key]
                del self.creation_times[key]
                removed_count += 1
            
            if removed_count > 0:
                self.stats["total_removed"] += removed_count
                self.stats["expired_items"] += removed_count
                logger.info(f"{self.name} 캐시에서 {removed_count}개 만료 항목 제거 (보존 기간: {self.retention_seconds}초)")
        
        return removed_count
    
    def size(self) -> int:
        """현재 캐시 크기 반환"""
        with self.lock:
            return len(self.cache)
            
    def keys(self) -> List[str]:
        """현재 캐시에 있는 모든 키 반환"""
        with self.lock:
            return list(self.cache.keys())
            
    def get_stats(self) -> Dict[str, int]:
        """캐시 통계 정보 반환"""
        with self.lock:
            stats_copy = self.stats.copy()
            stats_copy["current_size"] = len(self.cache)
            if self.retention_seconds:
                stats_copy["retention_seconds"] = self.retention_seconds
            return stats_copy
    
    def get_oldest_item_age(self) -> float:
        """가장 오래된 항목의 시간 반환 (초)"""
        with self.lock:
            if not self.creation_times:
                return 0
            oldest_time = min(self.creation_times.values())
            return time.time() - oldest_time

# 캐시 인스턴스 생성 (요약 데이터는 더 오래 보관)
summary_cache = DataCache("summary", max_size=500000, retention_seconds=SUMMARY_CACHE_RETENTION)
id_cache = DataCache("id", max_size=500000)

# 처리 중인 관리번호와 시작 시간을 기록
processing_ids = {}  # management_id -> start_time
processing_lock = threading.Lock()

# 처리 완료된 관리번호 세트 (추가 처리 방지)
completed_ids = set()
completed_lock = threading.Lock()

# 마지막 주기적 처리 시간
last_periodic_processing = time.time()

# 마지막 상태 출력 시간
last_status_time = time.time()

# 처리 통계
stats = {
    "summary_messages": 0,
    "id_messages": 0,
    "merged_messages": 0,
    "api_errors": 0,
    "api_calls": 0,  # API 호출 횟수 추적 추가
    "start_time": time.time()
}

# API 재시도 세션 설정
def create_retry_session():
    """재시도 로직이 포함된 requests 세션 생성"""
    session = requests.Session()
    retry = Retry(
        total=3,                 # 최대 3번 재시도
        backoff_factor=0.5,      # 재시도 간 대기 시간 증가
        status_forcelist=[429, 500, 502, 503, 504],  # 재시도할 상태 코드
        allowed_methods=["GET"]  # GET 요청만 재시도
    )
    adapter = HTTPAdapter(max_retries=retry)
    session.mount("http://", adapter)
    session.mount("https://", adapter)
    return session

# 공유 세션 객체 생성
api_session = create_retry_session()

def cleanup_processing_ids():
    """오래된 처리 중 항목 정리"""
    current_time = time.time()
    timed_out_count = 0
    
    with processing_lock:
        # 너무 많은 항목이 있으면 더 적극적으로 정리
        # 처리 중인 항목 수에 따라 타임아웃 기준을 동적으로 조정
        effective_timeout = PROCESSING_TIMEOUT
        if len(processing_ids) > MAX_PROCESSING_ITEMS * 0.8:  # 80% 이상 차면
            # 처리 항목이 많을수록 타임아웃 기준을 낮춤
            factor = min(len(processing_ids) / MAX_PROCESSING_ITEMS, 1.0)
            effective_timeout = max(PROCESSING_TIMEOUT * (1 - factor * 0.5), 10)  # 최소 10초
            logger.warning(f"처리 중인 항목이 많아 타임아웃 기준 조정: {effective_timeout:.1f}초")
        
        # 시간 초과된 항목 찾기
        timed_out_ids = [
            id for id, start_time in processing_ids.items()
            if current_time - start_time > effective_timeout
        ]
        
        # 시간 초과된 항목 제거
        for id in timed_out_ids:
            start_time = processing_ids.get(id, current_time)
            del processing_ids[id]
            timed_out_count += 1
            logger.warning(f"처리 시간 초과로 항목 제거: {id} (경과: {current_time - start_time:.1f}초)")
            
            # 캐시에서도 제거하여 재처리 가능하게 함
            summary_cache.remove(id)
            id_cache.remove(id)
        
        # 처리 중인 항목이 MAX_PROCESSING_ITEMS의 90% 이상이면 적극적으로 정리
        if len(processing_ids) > MAX_PROCESSING_ITEMS * 0.9:
            logger.warning(f"처리 중인 항목이 많음 ({len(processing_ids)}개), 강제 정리 시작")
            
            # 가장 오래된 항목부터 정리 (총 항목의 30%까지)
            sorted_ids = sorted(processing_ids.items(), key=lambda x: x[1])
            remove_count = max(int(len(processing_ids) * 0.3), 5)  # 최소 5개는 제거
            to_remove = sorted_ids[:remove_count]
            
            for id, start_time in to_remove:
                del processing_ids[id]
                timed_out_count += 1
                logger.warning(f"처리 항목 과다로 강제 제거: {id} (경과: {current_time - start_time:.1f}초)")
                
                # 캐시에서도 제거하여 재처리 가능하게 함
                summary_cache.remove(id)
                id_cache.remove(id)
                
    return timed_out_count

def api_worker_thread():
    """
    API 요청 작업자 스레드: 큐에서 API 요청 작업을 가져와 실행
    일정한 간격으로 API 호출을 수행하여 속도 제한 준수
    """
    last_api_call_time = 0
    
    while not api_worker_stop_event.is_set():
        try:
            # 큐에서 작업 가져오기 (타임아웃 1초)
            try:
                task = api_request_queue.get(timeout=1.0)
            except queue.Empty:
                # 큐가 비어있으면 다시 반복
                continue
            
            # API 호출 간격 제어
            elapsed = time.time() - last_api_call_time
            if elapsed < API_CALL_INTERVAL:
                # 마지막 API 호출 이후 API_CALL_INTERVAL 시간이 지나지 않았다면 대기
                sleep_time = API_CALL_INTERVAL - elapsed
                logger.debug(f"API 속도 제한: {sleep_time:.2f}초 대기")
                time.sleep(sleep_time)
            
            # 작업 실행
            management_id, fd_sn, merged_data = task
            process_api_request(management_id, fd_sn, merged_data)
            
            # 마지막 API 호출 시간 업데이트
            last_api_call_time = time.time()
            
            # 작업 완료 표시
            api_request_queue.task_done()
            
        except Exception as e:
            logger.error(f"API 작업자 스레드 오류: {e}")
            import traceback
            logger.error(f"상세 오류: {traceback.format_exc()}")
            # 오류가 발생해도 스레드는 계속 실행
            time.sleep(1)

def process_api_request(management_id: str, fd_sn: str, merged_data: Dict[str, Any]) -> None:
    """
    단일 API 요청 처리: 상세 정보 API 호출 및 결과 처리
    """
    api_start_time = time.time()
    logger.info(f"API 호출 시작: {management_id} (fdSn: {fd_sn})")
    
    try:
        stats["api_calls"] += 1  # API 호출 통계 추가
        
        # 타임아웃이 적용된 API 호출
        detail_xml = None
        try:
            # 타임아웃 설정이 있는 API 호출 래퍼 함수 사용
            detail_xml = fetch_lost_item_detail(management_id, fd_sn)
            if not detail_xml:
                raise Exception("API에서 빈 응답 반환")
        except Exception as api_err:
            logger.warning(f"기본 API 호출 실패: {management_id} - {api_err}")
            raise api_err  # 예외를 다시 발생시켜 아래 처리로 넘김
            
        api_duration = time.time() - api_start_time
        logger.info(f"API 응답 수신: {management_id} (소요 시간: {api_duration:.2f}초)")
        
        detail_info = parse_detail(detail_xml)
        
        if detail_info is None:
            detail_info = {
                "status": "TRANSFERRED", 
                "location": "", 
                "phone": "", 
                "detail": ""
            }
            logger.warning(f"상세 정보 없음: {management_id}")
    except Exception as e:
        api_duration = time.time() - api_start_time
        logger.error(f"상세 API 호출 에러 for {management_id} (fdSn: {fd_sn}, 경과: {api_duration:.2f}초): {e}")
        stats["api_errors"] += 1
        detail_info = {
            "status": "RECEIVED", 
            "location": "", 
            "phone": "", 
            "detail": f"API 오류: {str(e)[:100]}"  # 오류 정보 추가 (제한된 길이)
        }
    
    try:
        # 최종 병합 데이터 생성
        merged_data.update(detail_info)
        
        # 결과 메시지를 Kafka에 전송
        send_to_kafka(KAFKA_TOPIC_DETAIL, merged_data, key=management_id)
        logger.info(f"관리번호 {management_id} 처리 완료")
    except Exception as e:
        logger.error(f"Kafka 메시지 전송 중 오류: {management_id}: {e}")
    finally:
        # 항상 처리 완료 작업 수행 (성공/실패 상관없이)
        try:
            # 처리 완료된 관리번호는 캐시에서 제거
            summary_cache.remove(management_id)
            id_cache.remove(management_id)
            
            # 처리 중 목록에서 제거
            with processing_lock:
                if management_id in processing_ids:
                    del processing_ids[management_id]
            
            # 처리 완료 목록에 추가
            with completed_lock:
                completed_ids.add(management_id)
            
            # 통계 업데이트 (실패해도 처리된 것으로 간주)
            stats["merged_messages"] += 1
        except Exception as cleanup_err:
            logger.error(f"정리 작업 중 오류: {management_id}: {cleanup_err}")
            # 최소한 처리 중 목록에서는 제거
            with processing_lock:
                if management_id in processing_ids:
                    del processing_ids[management_id]

def merge_and_process(management_id: str) -> None:
    """
    management_id를 기준으로 요약 데이터와 ID 데이터를 병합한 후,
    상세정보 API 호출 작업을 API 요청 큐에 추가합니다.
    """
    try:
        # 이미 처리 중이거나 처리 완료된 경우 건너뜀
        with processing_lock:
            if management_id in processing_ids:
                return
            
            # 처리 중인 항목이 너무 많으면 건너뜀 (부하 관리)
            if len(processing_ids) >= MAX_PROCESSING_ITEMS:
                logger.warning(f"처리 중인 항목이 너무 많음 ({len(processing_ids)}개), 건너뜀: {management_id}")
                return
        
        with completed_lock:
            if management_id in completed_ids:
                return
        
        # 요약 데이터와 ID 데이터 조회
        summary_data = summary_cache.get(management_id)
        id_data = id_cache.get(management_id)
        
        # 두 데이터가 모두 있는 경우에만 병합 처리
        if summary_data and id_data:
            with processing_lock:
                # 다시 한번 확인 (동시성 문제 방지)
                if management_id in processing_ids:
                    return
                # 처리 중으로 표시
                processing_ids[management_id] = time.time()
            
            # 두 메시지를 병합 (id_data의 값이 우선)
            merged_data = summary_data.copy()
            merged_data.update(id_data)
            
            # 상세 정보 API 호출 (API 요청 큐에 추가)
            fd_sn = merged_data.get("fdSn", "1")  # 기본값 "1"
            
            # 큐에 API 요청 작업 추가
            api_request_queue.put((management_id, fd_sn, merged_data))
            logger.info(f"API 요청 큐에 작업 추가: {management_id}")
    except Exception as e:
        logger.error(f"병합 및 처리 중 오류: {management_id}: {e}")
        # 오류 발생 시 처리 중 목록에서 제거하여 재시도 가능하게 함
        with processing_lock:
            if management_id in processing_ids:
                del processing_ids[management_id]

def process_message_without_merge(msg, max_retries=3) -> bool:
    """
    초기 데이터 수집 단계에서 사용할 메시지 처리 함수 - 캐시에 저장만 하고 병합은 하지 않음
    실패 시 최대 max_retries 횟수만큼 재시도
    성공 여부를 불리언으로 반환
    """
    # 메시지가 None이면 False 반환
    if msg is None:
        return False
    
    for retry in range(max_retries):
        try:
            # 메시지 디코딩 시도
            try:
                value = msg.value().decode('utf-8')
                data = json.loads(value)
            except UnicodeDecodeError:
                logger.error(f"메시지 디코딩 실패 (인코딩 문제) - 시도 {retry+1}/{max_retries}")
                if retry < max_retries - 1:
                    time.sleep(0.5)  # 재시도 전 짧은 대기
                    continue
                return False
            except json.JSONDecodeError:
                logger.error(f"JSON 파싱 실패 (유효하지 않은 JSON) - 시도 {retry+1}/{max_retries}")
                if retry < max_retries - 1:
                    time.sleep(0.5)
                    continue
                return False
            
            # management_id 확인
            management_id = data.get("management_id")
            if not management_id:
                logger.warning("management_id가 없는 메시지를 건너뜁니다.")
                return False  # 유효한 management_id가 없으면 재시도해도 의미 없음
            
            # 토픽 확인 및 캐시 저장
            current_topic = msg.topic()
            
            if current_topic == KAFKA_TOPIC_SUMMARY:
                # 요약 데이터 처리 (캐시만)
                summary_cache.put(management_id, data)
                stats["summary_messages"] += 1
                if stats["summary_messages"] % 1000 == 0:  # 로그 빈도 제한
                    logger.info(f"요약 데이터 캐시 저장: {stats['summary_messages']}개")
                elif retry > 0:  # 재시도 후 성공한 경우 로깅
                    logger.info(f"요약 데이터 캐시 저장 성공 (재시도 {retry+1}): {management_id}")
            elif current_topic == KAFKA_TOPIC_ID:
                # ID 데이터 처리 (캐시만)
                id_cache.put(management_id, data)
                stats["id_messages"] += 1
                if stats["id_messages"] % 100 == 0:  # 로그 빈도 제한
                    logger.info(f"ID 데이터 캐시 저장: {stats['id_messages']}개")
                elif retry > 0:  # 재시도 후 성공한 경우 로깅
                    logger.info(f"ID 데이터 캐시 저장 성공 (재시도 {retry+1}): {management_id}")
                else:
                    logger.debug(f"ID 데이터 캐시 저장: {management_id}")
            else:
                logger.warning(f"알 수 없는 토픽: {current_topic}, 메시지 건너뜀")
                return False  # 알 수 없는 토픽은 재시도해도 의미 없음
            
            # 성공적으로 처리 완료
            return True
            
        except Exception as e:
            # 처리 중 예외 발생
            if retry < max_retries - 1:
                logger.warning(f"메시지 처리 중 오류 (재시도 {retry+1}/{max_retries}): {e}")
                # 상세 스택 트레이스 출력
                import traceback
                logger.debug(f"상세 오류: {traceback.format_exc()}")
                time.sleep(0.5 * (retry + 1))  # 점진적으로 대기 시간 증가
                time.sleep(0.5 * (retry + 1))  # 점진적으로 대기 시간 증가
            else:
                logger.error(f"메시지 처리 최종 실패 (시도 {max_retries}/{max_retries}): {e}")
                if management_id:
                    logger.error(f"처리 실패한 메시지 ID: {management_id}")
                return False
    
    # 여기까지 오면 모든 재시도가 실패한 것
    return False

def process_message(msg) -> None:
    """
    Kafka 메시지 처리 로직 (개선됨)
    """
    try:
        value = msg.value().decode('utf-8')
        data = json.loads(value)
    except Exception as e:
        logger.error(f"메시지 디코딩 에러: {e}")
        return
    
    management_id = data.get("management_id")
    if not management_id:
        logger.warning("management_id가 없는 메시지를 건너뜁니다.")
        return
    
    # 이미 처리 완료된 항목은 건너뜀
    with completed_lock:
        if management_id in completed_ids:
            return
    
    try:
        current_topic = msg.topic()
        
        if current_topic == KAFKA_TOPIC_SUMMARY:
            # 요약 데이터 처리
            summary_cache.put(management_id, data)
            stats["summary_messages"] += 1
            if stats["summary_messages"] % 1000 == 0:  # 로그 빈도 제한
                logger.info(f"요약 데이터 캐시 저장: {stats['summary_messages']}개")
        elif current_topic == KAFKA_TOPIC_ID:
            # ID 데이터 처리 (ID 데이터는 항상 로깅)
            id_cache.put(management_id, data)
            stats["id_messages"] += 1
            logger.debug(f"ID 데이터 캐시 저장: {management_id}")
            
            # ID 데이터가 들어올 때마다 즉시 요약 데이터와 매칭 시도 (지연 도착 핵심 전략)
            summary_data = summary_cache.get(management_id)
            if summary_data:
                # 처리 중인 항목이 정해진 임계값보다 적을 때만 처리
                with processing_lock:
                    active_count = len(processing_ids)
                
                if active_count < MAX_PROCESSING_ITEMS * 0.5:  # 50% 미만일 때만 즉시 처리
                    logger.info(f"ID 데이터 도착 즉시 매칭 시도: {management_id}")
                    merge_and_process(management_id)
                else:
                    logger.info(f"ID 데이터 도착 매칭 발견 (처리 지연): {management_id}")
    except Exception as e:
        logger.error(f"메시지 처리 중 오류: {management_id}: {e}")

def check_pending_messages() -> int:
    """
    주기적으로 캐시를 검사하여 병합 가능한 메시지가 있는지 확인하고 처리합니다.
    처리된 메시지 수를 반환합니다.
    """
    processed_count = 0
    batch_count = 0
    
    try:
        # ID 데이터를 기준으로 요약 데이터 찾기 (더 효율적)
        # ID 데이터가 적으므로, ID 캐시의 모든 키를 확인하는 것이 더 효율적
        id_keys = id_cache.keys()
        
        # 데이터 균형 정보 로깅 (5분마다 또는 처리가 없을 때)
        current_time = time.time()
        static_stats = getattr(check_pending_messages, 'stats', {'last_log_time': 0, 'last_process_time': 0})
        check_pending_messages.stats = static_stats
        
        if (current_time - static_stats.get('last_log_time', 0) > 300 or  # 5분마다
            (processed_count == 0 and current_time - static_stats.get('last_process_time', 0) > 60)):  # 처리 없을 때 1분마다
            
            summary_size = summary_cache.size()
            id_size = id_cache.size()
            match_rate = 0
            if id_size > 0:
                # 남은 ID 데이터와 요약 데이터 간의 매칭률 계산
                matches = sum(1 for id in id_keys if summary_cache.get(id) is not None)
                match_rate = (matches / len(id_keys)) * 100 if id_keys else 0
            
            logger.info(f"데이터 균형: 요약={summary_size}, ID={id_size}, 매칭률={match_rate:.1f}%, 매칭 가능={len(id_keys)}")
            
            # 요약 캐시의 가장 오래된 항목 나이 확인
            oldest_summary_age = summary_cache.get_oldest_item_age()
            logger.info(f"요약 캐시 가장 오래된 항목 나이: {oldest_summary_age:.1f}초 (보존 기간: {SUMMARY_CACHE_RETENTION}초)")
            
            # 현재 큐에 있는 API 요청 수
            logger.info(f"API 요청 큐 크기: {api_request_queue.qsize()}, 처리 중인 항목: {len(processing_ids)}")
            
            static_stats['last_log_time'] = current_time
        
        # 처리 중인 항목이 너무 많으면 배치 처리 건너뜀
        with processing_lock:
            active_count = len(processing_ids)
        
        if active_count >= MAX_PROCESSING_ITEMS * 0.7:
            logger.info(f"처리 중인 항목이 많음 ({active_count}개), 배치 처리 건너뜀")
            return 0
        
        # API 요청 큐가 이미 많이 쌓여 있으면 배치 처리 건너뜀
        if api_request_queue.qsize() >= MAX_PROCESSING_ITEMS:
            logger.info(f"API 요청 큐가 가득 참 ({api_request_queue.qsize()}개), 배치 처리 건너뜀")
            return 0
        
        # 처리할 항목 목록 구성
        to_process = []
        
        for management_id in id_keys:
            # 최대 배치 크기 제한 (부하 관리)
            if len(to_process) >= MAX_BATCH_PROCESS:
                break
                
            # 이미 처리 중이거나 완료된 경우 건너뜀
            with processing_lock:
                if management_id in processing_ids:
                    continue
            
            with completed_lock:
                if management_id in completed_ids:
                    continue
            
            # 요약 메시지가 있는 경우 처리 목록에 추가
            if summary_cache.get(management_id):
                to_process.append(management_id)
        
        # 처리 목록의 항목들 처리
        if to_process:
            logger.info(f"배치 처리: {len(to_process)}개 항목 처리 시작")
            for management_id in to_process:
                merge_and_process(management_id)
                processed_count += 1
                batch_count += 1
        
        if processed_count > 0:
            static_stats['last_process_time'] = current_time
    except Exception as e:
        logger.error(f"대기 중인 메시지 처리 중 오류: {e}")
    
    return processed_count

def print_status() -> None:
    """현재 처리 상태 및 통계 출력"""
    try:
        elapsed = time.time() - stats["start_time"]
        rate = stats["merged_messages"] / elapsed if elapsed > 0 else 0
        api_rate = stats["api_calls"] / elapsed if elapsed > 0 else 0
        
        logger.info("=== 처리 상태 ===")
        logger.info(f"캐시 상태: summary={summary_cache.size()}, id={id_cache.size()}, processing={len(processing_ids)}, completed={len(completed_ids)}")
        logger.info(f"처리 통계: 요약={stats['summary_messages']}, ID={stats['id_messages']}, 병합={stats['merged_messages']}, API호출={stats['api_calls']}, API오류={stats['api_errors']}")
        logger.info(f"처리 속도: {rate:.2f} 메시지/초, API 호출: {api_rate:.2f} 호출/초 (총 {elapsed:.1f}초 경과)")
        
        # 데이터 지연 관련 정보 추가
        id_to_summary_ratio = (stats['id_messages'] / stats['summary_messages'] * 100) if stats['summary_messages'] > 0 else 0
        logger.info(f"데이터 비율: ID/요약 = {id_to_summary_ratio:.1f}% (ID 데이터 지연 가능성)")
        
        # 캐시 세부 통계
        summary_stats = summary_cache.get_stats()
        id_stats = id_cache.get_stats()
        
        # 0으로 나누기 오류 방지
        summary_hit_rate = 0.0
        if summary_stats['cache_hits'] + summary_stats['cache_misses'] > 0:
            summary_hit_rate = summary_stats['cache_hits'] / (summary_stats['cache_hits'] + summary_stats['cache_misses']) * 100
        
        id_hit_rate = 0.0
        if id_stats['cache_hits'] + id_stats['cache_misses'] > 0:
            id_hit_rate = id_stats['cache_hits'] / (id_stats['cache_hits'] + id_stats['cache_misses']) * 100
        
        logger.info(f"Summary 캐시: 추가={summary_stats['total_added']}, 제거={summary_stats['total_removed']}, 조회={summary_stats['total_retrieved']}, 적중률={summary_hit_rate:.1f}%")
        logger.info(f"ID 캐시: 추가={id_stats['total_added']}, 제거={id_stats['total_removed']}, 조회={id_stats['total_retrieved']}, 적중률={id_hit_rate:.1f}%")
        
        # API 큐 정보 추가
        logger.info(f"API 요청 큐: {api_request_queue.qsize()}개 대기 중")
        
        # 만료된 항목이 있으면 표시
        if 'expired_items' in summary_stats:
            logger.info(f"만료된 요약 항목: {summary_stats['expired_items']} (보존 기간: {summary_stats.get('retention_seconds', 'N/A')}초)")
        
        logger.info("================")
    except Exception as e:
        logger.error(f"상태 출력 중 오류: {e}")

def run_detail_service():
    """
    Kafka Topic SUMMARY(요약 데이터)와 Topic ID(관리번호/기본 데이터)를 모두 구독하고,
    management_id를 기준으로 두 메시지를 병합한 후 상세정보 API 호출 결과와 합쳐
    Kafka Topic DETAIL에 전송하는 서비스를 실행합니다.
    """
    global last_periodic_processing, last_status_time
    
    # API 작업자 스레드 시작
    api_worker_thread_instance = threading.Thread(target=api_worker_thread, daemon=True)
    api_worker_thread_instance.start()
    logger.info("API 작업자 스레드 시작됨")
    
    # 소비자 설정
    consumer_conf = {
        'bootstrap.servers': KAFKA_BOOTSTRAP_SERVERS,
        'group.id': 'detail_service_group',
        'auto.offset.reset': 'earliest',
        'enable.auto.commit': 'false',  # 자동 커밋으로 변경
        # 'auto.commit.interval.ms': 5000,  # 5초마다 자동 커밋
        'max.poll.interval.ms': 600000,  # 최대 폴링 간격 (10분)
        'session.timeout.ms': 60000,    # 세션 타임아웃 (1분)
        'fetch.max.bytes': 52428800,    # 최대 50MB
        'max.partition.fetch.bytes': 1048576,  # 최대 1MB/파티션
        'receive.message.max.bytes': 104857600  # 최대 100MB
    }
    
    consumer = None
    last_cleanup_time = time.time()  # 정리 주기 추적용
    service_start_time = time.time()  # 서비스 시작 시간
    batch_processing_start_time = time.time()  # 배치 처리 시작 시간
    initial_data_collection = True  # 초기 데이터 수집 단계 플래그
    
    try:
        consumer = Consumer(consumer_conf)
        # 두 토픽 모두 구독
        consumer.subscribe([KAFKA_TOPIC_SUMMARY, KAFKA_TOPIC_ID])
        
        logger.info("상세 정보 수집 서비스 시작")
        stats["start_time"] = time.time()
        
        # 초기 데이터 수집을 위한 루프
        logger.info(f"초기 데이터 수집 단계 시작 (대기 시간: {PROCESSING_START_DELAY}초)")
        initial_end_time = time.time() + PROCESSING_START_DELAY
        import random
        
        while time.time() < initial_end_time and initial_data_collection:
            try:
                # 메시지 폴링 (짧은 타임아웃으로 최대한 많은 메시지 수집)
                msg = consumer.poll(timeout=0.5)
                if msg is None:
                    continue

                # 가끔 메시지 샘플링하여 원본 내용 로깅
                if random.random() < 0.01:  # 1% 확률로 로깅
                    try:
                        value = msg.value().decode('utf-8')
                        logger.debug(f"샘플 메시지: {value[:200]}...")  # 앞부분만 로깅
                    except:
                        logger.debug(f"메시지 디코딩 불가: {msg}")
                    
                if msg.error():
                    err_str = str(msg.error())
                    if "EOF" in err_str:  # EOF가 포함된 모든 에러 메시지 처리
                        # 파티션 끝에 도달: 정상적인 상황
                        continue
                    logger.error(f"Kafka 에러: {msg.error()}")
                    continue
                
                # 초기 단계에서는 메시지를 캐시만 하고 처리는 하지 않음
                success = process_message_without_merge(msg)
                # 성공적으로 처리된 경우에만 커밋
                if success:
                    consumer.commit(msg)
                
                # 5초마다 상태 출력
                if time.time() - last_status_time >= 5:
                    remaining = initial_end_time - time.time()
                    logger.info(f"초기 데이터 수집 중: summary={summary_cache.size()}, id={id_cache.size()} (남은 시간: {max(0, remaining):.1f}초)")
                    last_status_time = time.time()
                    
            except Exception as e:
                logger.error(f"초기 데이터 수집 중 오류: {e}")
                time.sleep(1)
        
        logger.info(f"초기 데이터 수집 완료: summary={summary_cache.size()}, id={id_cache.size()}")
        initial_data_collection = False
        
        # 메인 처리 루프
        last_message_time = time.time()  # 마지막 메시지 수신 시간 추적
        idle_shutdown_timeout = 300  # 5분간 메시지 없으면 종료

        while True:
            try:
                current_time = time.time()

                # 일정 시간 동안 메시지가 없고 모든 작업이 완료된 경우 종료
                if (current_time - last_message_time > idle_shutdown_timeout and 
                    summary_cache.size() == 0 and 
                    id_cache.size() == 0 and 
                    len(processing_ids) == 0 and
                    api_request_queue.qsize() == 0):
                    logger.info(f"{idle_shutdown_timeout}초 동안 새 메시지 없음, 모든 데이터 처리 완료. 서비스 종료.")
                    break
                
                # 요약 캐시 만료 항목 정리 (1시간에 한 번)
                if (current_time - service_start_time) % 3600 < 10:  # 서비스 시작 후 매 시간마다 10초 이내에 실행
                    expired = summary_cache.cleanup_expired()
                    if expired > 0:
                        logger.info(f"요약 캐시 만료 항목 정리: {expired}개 제거됨")
                
                # 처리 중인 항목이 많을 때 더 자주 정리 수행
                if len(processing_ids) > MAX_PROCESSING_ITEMS * 0.8 or current_time - last_cleanup_time >= CLEANUP_INTERVAL:
                    cleaned = cleanup_processing_ids()
                    if cleaned > 0:
                        logger.info(f"처리 중 목록 정리: {cleaned}개 항목 제거")
                    last_cleanup_time = current_time
                
                # 10초마다 상태 출력
                if current_time - last_status_time >= 10:
                    print_status()
                    last_status_time = current_time
                
                # 정기적인 배치 처리 (BATCH_PROCESSING_INTERVAL초마다)
                if current_time - batch_processing_start_time >= BATCH_PROCESSING_INTERVAL:
                    # API 요청 큐와 처리 중인 항목 수 확인
                    queue_size = api_request_queue.qsize()
                    with processing_lock:
                        active_count = len(processing_ids)
                    
                    # API 요청 큐와 처리 중인 항목 수가 적을 때만 배치 처리 수행
                    if queue_size <= MAX_PROCESSING_ITEMS * 0.3 and active_count <= MAX_PROCESSING_ITEMS * 0.5:
                        # global 선언을 먼저!
                        global MAX_BATCH_PROCESS
                        # 한 번에 처리할 최대 항목 수 제한
                        temp_max_batch = MAX_BATCH_PROCESS
                        # API 요청 큐 상태에 따라 동적으로 최대 배치 크기 조정
                        available_capacity = MAX_PROCESSING_ITEMS - queue_size - active_count
                        max_batch_size = min(MAX_BATCH_PROCESS, max(1, int(available_capacity * 0.5)))
                        
                        MAX_BATCH_PROCESS = max_batch_size
                        
                        processed = check_pending_messages()
                        
                        # 원래 값으로 복원
                        MAX_BATCH_PROCESS = temp_max_batch
                        
                        if processed > 0:
                            logger.info(f"정기 배치 처리: {processed}개 대기 메시지 처리 완료")
                        else:
                            logger.info("정기 배치 처리: 처리할 메시지 없음")
                    else:
                        logger.warning(f"처리 중인 항목이 많음 (큐={queue_size}, 처리 중={active_count}), 정기 배치 처리 건너뜀")
                    
                    batch_processing_start_time = current_time
                
                # 메시지 폴링 (짧은 타임아웃으로 주기적 처리를 자주 수행)
                msg = consumer.poll(timeout=0.5)
                if msg is None:
                    continue
                    
                if msg.error():
                    err_str = str(msg.error())
                    if "EOF" in err_str:  # EOF가 포함된 모든 에러 메시지 처리
                        # 파티션 끝에 도달: 정상적인 상황
                        continue
                    logger.error(f"Kafka 에러: {msg.error()}")
                    continue

                # 메시지를 수신했으므로 last_message_time 업데이트
                last_message_time = current_time
                
                # 처리 중인 항목이 많으면 새 메시지 처리 일시 중단 (부하 조절)
                if len(processing_ids) < MAX_PROCESSING_ITEMS * 0.9:
                    process_message(msg)
                else:
                    # ID 메시지는 항상 처리 (부족한 자원이므로)
                    if msg.topic() == KAFKA_TOPIC_ID:
                        process_message(msg)
                    else:
                        # 로그 빈도 제한: 100개 요약 메시지마다 한 번만 경고
                        if stats["summary_messages"] % 100 == 0:
                            logger.warning(f"처리 중인 항목이 많음 ({len(processing_ids)}개), 요약 메시지 수신 일시 중단")
                    
            except Exception as e:
                logger.error(f"메시지 처리 루프 중 오류: {e}")
                import traceback
                logger.error(f"상세 오류: {traceback.format_exc()}")
                # 심각한 오류가 아니라면 계속 실행
                time.sleep(1)  # 약간의 지연을 두고 계속 진행
                
            # 정리 작업을 더 자주 수행하여 시스템 복구 가능성 향상
            if len(processing_ids) > MAX_PROCESSING_ITEMS * 0.7:
                cleanup_processing_ids()
    except KeyboardInterrupt:
        logger.info("상세 정보 수집 서비스 중단")
    except Exception as e:
        logger.error(f"서비스 실행 중 오류 발생: {e}")
        import traceback
        logger.error(f"상세 오류: {traceback.format_exc()}")
    finally:
        # 예외 처리를 포함한 최종 상태 출력
        try:
            print_status()
        except Exception as e:
            logger.error(f"최종 상태 출력 중 오류 발생: {e}")
        
        # 마지막으로 대기 중인 메시지 처리 시도
        try:
            processed = check_pending_messages()
            if processed > 0:
                logger.info(f"종료 전 최종 처리: {processed}개 대기 메시지 처리 완료")
        except Exception as e:
            logger.error(f"최종 메시지 처리 중 오류 발생: {e}")
            
        # 항상 소비자 닫기
        try:
            if consumer:
                consumer.close()
        except Exception as e:
            logger.error(f"소비자 닫기 중 오류 발생: {e}")
            
        # API 작업자 스레드 종료
        try:
            logger.info("API 작업자 스레드 종료 신호 전송")
            api_worker_stop_event.set()
            # 남은 큐 항목 처리 대기
            if not api_request_queue.empty():
                logger.info(f"남은 API 요청 {api_request_queue.qsize()}개 처리 대기 중...")
                api_request_queue.join()
        except Exception as e:
            logger.error(f"API 작업자 스레드 종료 중 오류: {e}")
            
        logger.info("상세 정보 수집 서비스 종료")

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, 
                      format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    run_detail_service()