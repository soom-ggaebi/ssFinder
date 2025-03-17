import requests
import xmltodict
from config.config import API_SERVICE_KEY

def fetch_bulk_items(start_ymd: str, end_ymd: str, page_no: int = 1, num_of_rows: int = 1000):
    """
    한 번에 최대 1~10000개씩 가져오는 간략 정보 API (XML 응답).
    """
    url = 'http://apis.data.go.kr/1320000/LosfundInfoInqireService/getLosfundInfoAccToClAreaPd'
    params = {
        'serviceKey': API_SERVICE_KEY,
        'START_YMD': start_ymd,
        'END_YMD': end_ymd,
        'pageNo': page_no,
        'numOfRows': num_of_rows
    }
    resp = requests.get(url, params=params)
    resp.raise_for_status()
    return xmltodict.parse(resp.content)

def fetch_detail_item(atc_id: str, fd_sn: str = "1"):
    """
    관리번호(ATC_ID)로 1개씩 상세 정보를 가져오는 API.
    """
    detail_url = 'http://apis.data.go.kr/1320000/LosfundInfoInqireService/getLosfundDetailInfo'
    params = {
        'serviceKey': API_SERVICE_KEY,
        'ATC_ID': atc_id,
        'FD_SN': fd_sn
    }
    resp = requests.get(detail_url, params=params)
    resp.raise_for_status()
    return xmltodict.parse(resp.content)