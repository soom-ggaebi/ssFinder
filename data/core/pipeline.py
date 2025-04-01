"""
데이터 파이프라인 통합 모듈
전체 데이터 수집, 처리, 저장 파이프라인을 실행합니다.

최적화 전략:
1. 서비스 단위로 독립적인 스레드에서 실행
2. 리소스 관리 및 모니터링
"""
import threading
import time
import logging
import signal
import sys
from typing import Optional

from core.producer_bulk import run_bulk_producer
from core.kafka_consumer import run_kafka_consumer_continuous
from core.detail_service import run_detail_service
from utils.concurrency import ThreadPoolManager

logger = logging.getLogger(__name__)

# 파이프라인 제어용 이벤트
shutdown_event = threading.Event()

def signal_handler(sig, frame):
    """Ctrl+C 시그널 처리 핸들러"""
    logger.info("종료 시그널 감지, 파이프라인을 안전하게 종료합니다...")
    shutdown_event.set()

def run_producer_service(start_date=None, end_date=None):
    """프로듀서 서비스 실행 (별도 스레드)"""
    try:
        logger.info("데이터 수집 서비스 시작 (프로듀서)")
        run_bulk_producer(start_date, end_date)
        logger.info("데이터 수집 서비스 완료")
    except Exception as e:
        logger.error(f"데이터 수집 서비스 에러: {e}")
        import traceback
        logger.error(f"상세 오류: {traceback.format_exc()}")
        # 심각한 에러 발생 시 전체 파이프라인 종료
        shutdown_event.set()

def run_detail_service_wrapper():
    """상세 정보 수집 서비스 실행 (별도 스레드)"""
    try:
        logger.info("상세 정보 수집 서비스 시작")
        run_detail_service()
        logger.info("상세 정보 수집 서비스 종료")
    except Exception as e:
        logger.error(f"상세 정보 수집 서비스 에러: {e}")
        import traceback
        logger.error(f"상세 오류: {traceback.format_exc()}")
        shutdown_event.set()

def run_consumer_service():
    """소비자 서비스 실행 (별도 스레드)"""
    try:
        logger.info("데이터 처리 및 저장 서비스 시작 (소비자)")
        run_kafka_consumer_continuous()
        logger.info("데이터 처리 및 저장 서비스 종료")
    except Exception as e:
        logger.error(f"데이터 처리 및 저장 서비스 에러: {e}")
        import traceback
        logger.error(f"상세 오류: {traceback.format_exc()}")
        shutdown_event.set()

def run_pipeline(start_date: Optional[str] = None, end_date: Optional[str] = None, 
                sequential_mode: bool = False, register_signals: bool = True):
    """
    전체 파이프라인 실행:
      1. 요약 데이터 수집 및 Kafka 전송 (프로듀서) - 시작일과 종료일 사용
      2. 상세 정보 조회 서비스 실행 (비동기)
      3. Kafka 소비 및 이미지 전처리+지오코딩 후 DB/S3/HDFS/ES 저장 (소비자)
      
    Args:
        start_date: 데이터 수집 시작일 (YYYYMMDD 형식, 선택사항)
        end_date: 데이터 수집 종료일 (YYYYMMDD 형식, 선택사항)
        sequential_mode: 순차 실행 모드 여부 (기본값: False) 
                         True면 프로듀서 완료 후 다른 서비스 시작
        register_signals: 시그널 핸들러 등록 여부 (메인 스레드에서만 True로 설정)
    """
    # 시그널 핸들러 등록 (메인 스레드에서만)
    if register_signals:
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
    
    # 시작 전 shutdown_event 초기화
    shutdown_event.clear()
    
    # 시작 로그
    logger.info("데이터 파이프라인 시작")
    logger.info(f"설정: start_date={start_date}, end_date={end_date}, sequential_mode={sequential_mode}")
    
    threads = []
    start_time = time.time()
    
    try:
        if sequential_mode:
            # 순차 실행 모드: 프로듀서 먼저 실행 후 다른 서비스 시작
            logger.info("순차 실행 모드: 프로듀서 먼저 실행")
            run_producer_service(start_date, end_date)
            
            # 프로듀서 완료 후 다른 서비스 시작
            if not shutdown_event.is_set():
                detail_thread = threading.Thread(target=run_detail_service_wrapper, daemon=True)
                consumer_thread = threading.Thread(target=run_consumer_service, daemon=True)
                
                detail_thread.start()
                consumer_thread.start()
                
                threads = [detail_thread, consumer_thread]
        else:
            # 병렬 실행 모드: 모든 서비스 동시 시작
            logger.info("병렬 실행 모드: 모든 서비스 동시 시작")
            producer_thread = threading.Thread(target=run_producer_service, args=(start_date, end_date), daemon=True)
            detail_thread = threading.Thread(target=run_detail_service_wrapper, daemon=True)
            consumer_thread = threading.Thread(target=run_consumer_service, daemon=True)
            
            producer_thread.start()
            detail_thread.start()
            consumer_thread.start()
            
            threads = [producer_thread, detail_thread, consumer_thread]
        
        # 종료 대기
        while not shutdown_event.is_set() and any(t.is_alive() for t in threads):
            # 주기적으로 스레드 상태 확인
            alive_count = sum(1 for t in threads if t.is_alive())
            logger.debug(f"실행 중인 스레드: {alive_count}/{len(threads)}")
            
            # 진행 상황 주기적 로깅 (1분마다)
            elapsed_time = time.time() - start_time
            if int(elapsed_time) % 60 == 0:
                logger.info(f"파이프라인 실행 중: {elapsed_time:.0f}초 경과")
                
            time.sleep(5)
            
        # 모든 스레드 종료 대기
        for t in threads:
            if t.is_alive():
                t.join(timeout=10)  # 최대 10초 대기
        
        # 스레드 풀 종료
        try:
            pool_manager = ThreadPoolManager()
            pool_manager.shutdown()
        except Exception as e:
            logger.error(f"스레드 풀 종료 중 오류: {e}")
        
        # 종료 로그
        elapsed_time = time.time() - start_time
        logger.info(f"데이터 파이프라인 종료: {elapsed_time:.2f}초 소요")
        
    except KeyboardInterrupt:
        logger.info("사용자에 의한 중단 요청")
        shutdown_event.set()
    except Exception as e:
        logger.error(f"파이프라인 실행 중 예외 발생: {e}")
        import traceback
        logger.error(f"상세 오류: {traceback.format_exc()}")
        shutdown_event.set()
    finally:
        # 모든 스레드가 종료되지 않은 경우 경고
        for t in threads:
            if t.is_alive():
                logger.warning(f"스레드가 정상적으로 종료되지 않았습니다: {t.name}")
        
        # 백그라운드에서 실행 중인 경우 (FastAPI 백그라운드 태스크) 시스템 종료를 호출하지 않음
        if register_signals:
            # 종료 코드를 반환하는 대신 함수 종료
            return 0 if not shutdown_event.is_set() else 1

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO,
                      format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    exit_code = run_pipeline()
    sys.exit(exit_code)