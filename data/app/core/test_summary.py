# test_summary.py
from app.models.common.api_client import fetch_lost_items
from app.models.response.lost_item_response import parse_total_count, parse_items
from app.core.kafka_producer import send_to_kafka

def test_summary_api_and_kafka():
    # API 호출: 1페이지 1,000건씩 호출
    xml_data = fetch_lost_items(page_no=1, num_of_rows=1000)
    total_count = parse_total_count(xml_data)
    items = parse_items(xml_data)
    
    print("총 건수:", total_count)
    print("파싱된 항목 예시:", items[:3])
    
    # 각 항목을 Kafka에 전송 (테스트)
    for item in items:
        if item.get("management_id"):
            send_to_kafka(item)
            print(f"전송 완료: {item['management_id']}")
            
if __name__ == "__main__":
    test_summary_api_and_kafka()
