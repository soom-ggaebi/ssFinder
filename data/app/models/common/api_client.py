import requests
from config.config import API_SERVICE_KEY
from app.models.common.date_util import get_date_range_for_api

def fetch_lost_items(page_no=1, num_of_rows=1000):
    start_ymd, end_ymd = get_date_range_for_api()
    url = 'http://apis.data.go.kr/1320000/LosfundInfoInqireService/getLosfundInfoAccToClAreaPd'
    params = {
        'serviceKey': API_SERVICE_KEY,
        'START_YMD': start_ymd,
        'END_YMD': end_ymd,
        'pageNo': page_no,
        'numOfRows': num_of_rows
    }
    resp = requests.get(url, params=params)
    if resp.status_code == 200:
        return resp.text
    else:
        raise Exception(f"[목록] API 요청 실패 (status: {resp.status_code})")

def fetch_lost_item_detail(atc_id):
    url = 'http://apis.data.go.kr/1320000/LosfundInfoInqireService/getLosfundDetailInfo'
    params = {
        'serviceKey': API_SERVICE_KEY,
        'ATC_ID': atc_id,
        'FD_SN': 1
    }
    resp = requests.get(url, params=params)
    if resp.status_code == 200:
        return resp.text
    else:
        raise Exception(f"[상세] API 요청 실패 (status: {resp.status_code})")
