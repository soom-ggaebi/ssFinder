# test_detail_service.py
from app.models.common.api_client import fetch_lost_item_detail
from app.models.response.lost_item_response import parse_detail
from app.core.kafka_producer import send_to_kafka

def test_detail_api_and_kafka(management_id):
    try:
        xml_detail = fetch_lost_item_detail(management_id)
        detail_data = parse_detail(xml_detail)
        print("상세 데이터:", detail_data)
        send_to_kafka(detail_data)
        print(f"상세 데이터 전송 완료: {management_id}")
    except Exception as e:
        print(f"상세 API 호출 실패: {e}")

if __name__ == "__main__":
    test_detail_api_and_kafka("F2025032200000093")
