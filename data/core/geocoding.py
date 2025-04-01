import os
import re
import requests
import logging

# 캐시 딕셔너리: 주소 문자열 -> (latitude, longitude)
_geocode_cache = {}

logger = logging.getLogger(__name__)

def geocode_location(location: str) -> (float, float):
    if not location:
        return None, None
        
    # 특수문자와 괄호 제거, 숫자와 한글, 영어 문자만 유지
    cleaned_location = re.sub(r'[^\w\s가-힣]', '', location)
    # 연속된 공백을 하나의 공백으로 변환
    cleaned_location = re.sub(r'\s+', ' ', cleaned_location).strip()
    
    # 이미 캐시에 있으면 캐시된 결과 반환 (정제된 주소로 확인)
    if cleaned_location in _geocode_cache:
        return _geocode_cache[cleaned_location]

    logger.info(f"원본 주소: '{location}' -> 정제된 주소: '{cleaned_location}'")

    api_key = os.getenv("GEOCODING_API_KEY")
    if not api_key:
        logger.warning("GEOCODING_API_KEY가 제공되지 않았습니다.")
        _geocode_cache[cleaned_location] = (None, None)
        return None, None

    base_url = "https://api.vworld.kr/req/address"
    params = {
        "service": "address",
        "request": "getcoord",
        "crs": "epsg:4326",
        "address": cleaned_location,  # 정제된 주소 사용
        "format": "json",
        "type": "road",
        "key": api_key
    }
    try:
        response = requests.get(base_url, params=params)
        if response.status_code == 200:
            data = response.json()
            if data.get("response") and data["response"].get("status") == "OK":
                point = data["response"]["result"]["point"]
                # Vworld API는 x가 경도, y가 위도입니다.
                logger.info(f"지오코딩 결과: {point}")
                latitude = float(point["y"])
                longitude = float(point["x"])
                _geocode_cache[cleaned_location] = (latitude, longitude)
                return latitude, longitude
            else:
                logger.warning(f"지오코딩 결과 없음: {cleaned_location}")
                _geocode_cache[cleaned_location] = (None, None)
                return None, None
        else:
            logger.warning(f"지오코딩 API 에러: {response.status_code}")
            _geocode_cache[cleaned_location] = (None, None)
            return None, None
    except Exception as e:
        logger.error(f"지오코딩 요청 에러 ({cleaned_location}): {e}")
        _geocode_cache[cleaned_location] = (None, None)
        return None, None