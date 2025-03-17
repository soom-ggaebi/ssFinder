from fastapi import APIRouter, HTTPException
from app.core.producer_bulk import produce_bulk_messages
from app.core.producer_detail import produce_detail_messages
from app.models.common.date_util import get_date_range

router = APIRouter()

@router.get("/lost-items/bulk")
def fetch_bulk_data(initial: bool = False, page_no: int = 1, num_of_rows: int = 1000):
    """
    Bulk API 트리거:
      - initial=True -> 6개월 전부터 전날까지
      - initial=False -> 오늘 데이터
    """
    try:
        start_ymd, end_ymd = get_date_range(initial)
        produce_bulk_messages(start_ymd, end_ymd, page_no, num_of_rows)
        return {"message": "Bulk data sent to Kafka.", "start": start_ymd, "end": end_ymd}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/lost-items/detail")
def fetch_detail_data(atc_ids: list[str]):
    """
    Detail API 트리거:
      - Body로 ATC_ID 리스트를 받아, 상세 정보 API 호출 후 Kafka 전송
    """
    try:
        produce_detail_messages(atc_ids)
        return {"message": f"Sent detail data for {len(atc_ids)} items."}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
