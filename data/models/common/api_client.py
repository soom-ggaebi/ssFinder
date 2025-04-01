import requests
from requests.exceptions import ChunkedEncodingError, RequestException
from config.config import API_SERVICE_KEY
from models.common.date_util import get_date_range_for_api

def fetch_lost_items(page_no=1, num_of_rows=1000, start_date=None, end_date=None):
    """
    API 호출로 분실물 요약 데이터를 수집합니다.
    시작일과 종료일이 제공되면 이를 사용하고, 제공되지 않으면 기본값(최근 6개월 전)을 사용합니다.
    """
    if not start_date or not end_date:
        start_ymd, end_ymd = get_date_range_for_api()
    else:
        start_ymd = start_date
        end_ymd = end_date

    url = "http://apis.data.go.kr/1320000/LosfundInfoInqireService/getLosfundInfoAccToClAreaPd"
    params = {
        "serviceKey": API_SERVICE_KEY,
        "START_YMD": start_ymd,
        "END_YMD": end_ymd,
        "pageNo": page_no,
        "numOfRows": num_of_rows
    }
    max_retries = 3
    for attempt in range(1, max_retries + 1):
        try:
            resp = requests.get(url, params=params, timeout=100)
            resp.raise_for_status()
            return resp.text
        except ChunkedEncodingError as e:
            print(f"[재시도 {attempt}/{max_retries}] ChunkedEncodingError 발생: {e}")
            if attempt == max_retries:
                raise Exception("API 요청 실패: ChunkedEncodingError")
        except RequestException as e:
            print(f"[재시도 {attempt}/{max_retries}] 요청 실패: {e}")
            if attempt == max_retries:
                raise Exception(f"API 요청 실패: {e}")

def fetch_lost_item_detail(atc_id, fd_sn):
    url = "http://apis.data.go.kr/1320000/LosfundInfoInqireService/getLosfundDetailInfo"
    params = {
        "serviceKey": API_SERVICE_KEY,
        "ATC_ID": atc_id,
        "FD_SN": fd_sn
    }
    resp = requests.get(url, params=params)
    if resp.status_code == 200:
        return resp.text
    else:
        raise Exception(f"상세 API 요청 실패 (status: {resp.status_code})")