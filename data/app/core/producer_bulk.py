import json
from datetime import datetime
from kafka import KafkaProducer
from app.models.common.api_client import fetch_bulk_items
from config.config import KAFKA_BROKER, KAFKA_BULK_TOPIC  # 오타 없는지 확인

def produce_bulk_messages(start_ymd, end_ymd, page_no=1, num_of_rows=1000):
    """
    Bulk API에서 최대 1~10000개 데이터를 가져와 Kafka로 전송.
    """
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BROKER,
        value_serializer=lambda v: json.dumps(v, ensure_ascii=False).encode('utf-8')
    )
    data = fetch_bulk_items(start_ymd, end_ymd, page_no, num_of_rows)
    
    # 응답 전체를 디버그용으로 출력 (운영 시에는 제거)
    print("Fetched API data:")
    print(json.dumps(data, ensure_ascii=False, indent=2))
    
    # header 검사: resultCode가 "00"이 아니면 에러 처리
    header = data.get("response", {}).get("header", {})
    if header.get("resultCode") != "00":
        print("API 에러:", header.get("resultMsg"))
        return

    items = data.get("response", {}).get("body", {}).get("items", {}).get("item", None)
    if items is None:
        print("No items found.")
        return
    if not isinstance(items, list):
        items = [items]  # 단일 item일 경우 리스트로 변환

    count = 0
    for item in items:
        message = {
            "type": "BULK",
            "timestamp": datetime.now().isoformat(),
            "data": item
        }
        producer.send(KAFKA_BULK_TOPIC, message)
        print(f"Sending message for atcId: {item.get('atcId')}")
        count += 1
    producer.flush()
    print(f"[BULK] Sent {count} items to Kafka topic '{KAFKA_BULK_TOPIC}'.")
