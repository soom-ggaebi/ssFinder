import json
from datetime import datetime
from kafka import KafkaProducer
from app.models.common.api_client import fetch_detail_item
from config.config import KAFKA_BROKER, KAFKA_DETAIL_TOPIC

def produce_detail_messages(atc_ids):
    """
    atc_ids: 관리번호(ATC_ID) 리스트
    각 ATC_ID마다 상세정보 API 호출 후 Kafka로 전송
    """
    producer = KafkaProducer(
        bootstrap_servers=KAFKA_BROKER,
        value_serializer=lambda v: json.dumps(v, ensure_ascii=False).encode('utf-8')
    )
    
    count = 0
    for atc_id in atc_ids:
        detail_data = fetch_detail_item(atc_id, fd_sn="1")
        item = detail_data.get("response", {}).get("body", {}).get("item", {})
        if not item:
            continue
        
        message = {
            "type": "DETAIL",
            "timestamp": datetime.now().isoformat(),
            "data": item
        }
        producer.send(KAFKA_DETAIL_TOPIC, message)
        count += 1
    producer.flush()
    print(f"[DETAIL] Sent {count} detail items to Kafka topic '{KAFKA_DETAIL_TOPIC}'.")
