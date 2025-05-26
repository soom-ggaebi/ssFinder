"""
요약 데이터 수집 및 Kafka 전송을 담당하는 프로듀서 모듈
최적화 전략:
1. 스레드 풀을 활용한 API 요청 병렬화
2. 배치 처리를 통한 Kafka 메시지 전송 최적화
3. 에러 처리 및 재시도 로직 개선
"""
import concurrent.futures
from models.common.api_client import fetch_lost_items
from models.response.lost_item_response import parse_total_count, parse_items
from core.kafka_producer import send_to_kafka, send_batch_to_kafka
from utils.concurrency import ThreadPoolManager, run_in_thread_pool
from config.config import (
    KAFKA_TOPIC_SUMMARY, KAFKA_TOPIC_ID, API_THREAD_POOL_SIZE,
    KAFKA_BATCH_SIZE, API_BATCH_SIZE
)
import logging
import time

logger = logging.getLogger(__name__)

@run_in_thread_pool(pool_type='api')
def fetch_page(page_no, num_of_rows, start_date, end_date):
    """
    단일 페이지의 요약 데이터를 API로 수집하는 함수
    스레드 풀에서 실행됩니다.
    """
    logger.info(f"페이지 {page_no} 요청 시작 (rows={num_of_rows})")
    try:
        xml_list = fetch_lost_items(page_no=page_no, num_of_rows=num_of_rows, 
                                   start_date=start_date, end_date=end_date)
        total_count = parse_total_count(xml_list)
        items = parse_items(xml_list)
        logger.info(f"페이지 {page_no} 수신 완료: {len(items)} 항목")
        return {"page": page_no, "total_count": total_count, "items": items}
    except Exception as e:
        logger.error(f"페이지 {page_no} 요청 실패: {e}")
        return {"page": page_no, "total_count": 0, "items": [], "error": str(e)}

def prepare_messages(items):
    """
    API로 받은 항목을 Kafka 메시지로 변환
    """
    summary_messages = []
    id_messages = []
    
    for data in items:
        management_id = data.get("management_id")
        if not management_id:
            continue
            
        fd_sn = data.get("fdSn")
        if not fd_sn:
            fd_sn = 1
            
        # Topic A: 전체 요약 데이터
        summary_messages.append({
            "key": management_id,
            "value": data
        })
        
        # Topic B: 관리번호, fd_sn 및 일부 요약 데이터
        topic_b_message = {
            "management_id": management_id,
            "fdSn": fd_sn,
            # 필요한 요약 필드를 함께 전송 (추후 상세정보와 병합)
            "name": data.get("name"),
            "color": data.get("color"),
            "stored_at": data.get("stored_at"),
            "image": data.get("image"),
            "found_at": data.get("found_at"),
            "prdtClNm": data.get("prdtClNm")
        }
        id_messages.append({
            "key": management_id,
            "value": topic_b_message
        })
    
    return summary_messages, id_messages

def run_bulk_producer(start_date=None, end_date=None):
    """
    API 호출로 요약 데이터를 수집하여 Kafka에 전송합니다.
    - 시작일(start_date)과 종료일(end_date)이 제공되면 이를 사용하여 데이터를 수집합니다.
    - 병렬 API 요청과 배치 Kafka 메시지 전송으로 최적화됩니다.
    """
    # 초기 API 요청으로 총 페이지 수 파악
    initial_response = fetch_page(1, API_BATCH_SIZE, start_date, end_date)
    total_count = initial_response.get("total_count", 0)
    
    if total_count == 0:
        logger.warning("데이터가 없습니다.")
        return
        
    total_pages = (total_count + API_BATCH_SIZE - 1) // API_BATCH_SIZE
    logger.info(f"총 {total_count}개 데이터, {total_pages}개 페이지 수집 예정")
    
    # 첫 페이지 처리
    initial_items = initial_response.get("items", [])
    summary_batch, id_batch = prepare_messages(initial_items)
    
    # 나머지 페이지 병렬 요청 및 처리
    pool_manager = ThreadPoolManager()
    futures = []
    
    # 페이지 2부터 병렬 요청 제출
    for page in range(2, total_pages + 1):
        future = pool_manager.submit_to_api_pool(
            fetch_page, page, API_BATCH_SIZE, start_date, end_date
        )
        futures.append(future)
        
    # 배치 처리를 위한 변수 초기화
    total_processed = len(initial_items)
    summary_batch_count = 0
    id_batch_count = 0
    
    # 첫 페이지 배치 처리
    if summary_batch:
        send_batch_to_kafka(KAFKA_TOPIC_SUMMARY, summary_batch)
        summary_batch_count += len(summary_batch)
    
    if id_batch:
        send_batch_to_kafka(KAFKA_TOPIC_ID, id_batch)
        id_batch_count += len(id_batch)
    
    # 나머지 페이지 완료된 순서대로 처리
    for future in concurrent.futures.as_completed(futures):
        try:
            result = future.result()
            page = result.get("page")
            items = result.get("items", [])
            
            if not items:
                logger.warning(f"페이지 {page}에 항목이 없습니다.")
                continue
                
            logger.info(f"페이지 {page} 처리 중: {len(items)} 항목")
            
            # 메시지 준비 및 배치 처리
            summary_messages, id_messages = prepare_messages(items)
            
            if summary_messages:
                send_batch_to_kafka(KAFKA_TOPIC_SUMMARY, summary_messages)
                summary_batch_count += len(summary_messages)
                
            if id_messages:
                send_batch_to_kafka(KAFKA_TOPIC_ID, id_messages)
                id_batch_count += len(id_messages)
                
            total_processed += len(items)
            logger.info(f"진행 상황: {total_processed}/{total_count} 항목 처리됨 ({(total_processed/total_count)*100:.1f}%)")
            
        except Exception as e:
            logger.error(f"페이지 처리 중 에러 발생: {e}")
    
    logger.info(f"모든 페이지 처리 완료. 총 {summary_batch_count}개 요약 메시지, {id_batch_count}개 ID 메시지 전송됨")

def run_full_pipeline():
    """
    전체 파이프라인 실행: 요약 데이터 수집 및 Kafka 전송을 실행합니다.
    """
    start_time = time.time()
    run_bulk_producer()
    elapsed_time = time.time() - start_time
    logger.info(f"파이프라인 실행 완료: {elapsed_time:.2f}초 소요")
    
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO,
                       format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    run_full_pipeline()