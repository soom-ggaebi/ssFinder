from app.models.common.api_client import fetch_lost_items, fetch_lost_item_detail
from app.models.response.lost_item_response import parse_total_count, parse_items, parse_detail
from app.core.kafka_producer import send_to_kafka
#from app.spark.spark_processing import run_spark_job  # spark 작업 제거

def run_bulk_producer():
    """
    1. 목록 API를 1,000건씩 호출
    2. 각 아이템별 상세 API 호출하여 상세 정보 획득
    3. API 데이터(목록 + 상세)를 Kafka 메시지로 전송
    """
    page_no = 1
    num_of_rows = 1000
    total_messages = 0

    while True:
        xml_list = fetch_lost_items(page_no=page_no, num_of_rows=num_of_rows)
        total_count = parse_total_count(xml_list)
        items = parse_items(xml_list)
        if not items:
            break

        for data in items:
            if not data['management_id']:
                continue
            try:
                detail_xml = fetch_lost_item_detail(data['management_id'])
                detail_info = parse_detail(detail_xml)
            except Exception as e:
                print(f"상세 API 호출 실패: {e}")
                detail_info = {
                    'status': 'TRANSFERRED',
                    'location': '',
                    'phone': '',
                    'detail': ''
                }
            if detail_info is None:
                detail_info = {
                    'status': 'TRANSFERRED',
                    'location': '',
                    'phone': '',
                    'detail': ''
                }
            # 메시지 병합 (목록 + 상세)
            message = data.copy()
            message.update(detail_info)
            send_to_kafka(message)
            total_messages += 1

        total_pages = (total_count + num_of_rows - 1) // num_of_rows
        print(f"[페이지 {page_no}/{total_pages}] 전송 메시지 수: {len(items)} (누적: {total_messages})")
        if page_no >= total_pages:
            break
        page_no += 1

    print(f"모든 페이지 처리 완료. 총 Kafka 전송 메시지 수: {total_messages}")

def run_full_pipeline():
    """
    전체 파이프라인 실행:
    1. API 호출 및 Kafka 전송
    2. Kafka 메시지 소비 및 저장 (MySQL, S3, Hadoop)
    
    이제 API 호출 시 이 함수가 실행되어,
    전송된 Kafka 메시지를 소비하여 데이터베이스 및 스토리지에 저장까지 진행됩니다.
    """
    run_bulk_producer()
    # Kafka Consumer를 batch 방식으로 실행 (메시지가 없으면 지정 시간 후 종료)
    from app.core import kafka_consumer
    kafka_consumer.run_kafka_consumer_batch(max_idle_seconds=10)
