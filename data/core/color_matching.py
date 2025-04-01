import re
from rapidfuzz import process, fuzz

# 최종적으로 저장할 표준 색상 목록
ALLOWED_COLORS = [
    "검정색", "흰색", "회색", "베이지", "갈색", "빨간색",
    "주황색", "노란색", "초록색", "하늘색", "파란색", "남색",
    "보라색", "분홍색"
]

# 동의어 매핑: 여기 정의된 항목이 있으면 바로 표준 색상으로 변환
SYNONYM_MAPPING = {
    "블랙": "검정색",
    "검정": "검정색",
    "화이트": "흰색",
    "흰": "흰색",
    "그레이": "회색",
    "라이트그레이": "회색",
    "회색": "회색",
    "실버": "회색",         
    "베이지": "베이지",
    "갈색": "갈색",
    "브라운": "갈색",
    "갈": "갈색",
    "녹갈": "갈색",
    "빨강": "빨간색",
    "빨간": "빨간색",
    "레드": "빨간색",
    "다크레드": "빨간색",    
    "주황": "주황색",
    "오렌지": "주황색",
    "노랑": "노란색",
    "노란": "노란색",
    "엘로우": "노란색",
    "초록": "초록색",
    "그린": "초록색",
    "시안": "하늘색",     
    "코럴": "분홍색",       
    "터키오이스": "하늘색", 
    "퓨시아": "분홍색",     
    "다크바이올렛": "보라색",
    "보라": "보라색",
    "핑크": "분홍색",
    "분홍": "분홍색",
    "다크블루": "남색",     
    "다크시안": "남색",     
    "딥스카이블루": "하늘색",
    "라임": "초록색",      
    "라임그린": "초록색",   
    "네온그린": "초록색",
    "알리자린": "빨간색",
    "에메랄드": "초록색",
    "코발트": "파란색",
    "씨그린": "초록색"
}

def extract_candidates(input_color):
    """
    입력 문자열에서 괄호 안과 바깥의 텍스트를 각각 추출합니다.
    예) "블랙(검정)" -> ["검정", "블랙"]
    """
    if not input_color:
        return []
    candidates = []
    # 괄호 안의 텍스트 추출
    parenthetical = re.findall(r'\(([^)]*)\)', input_color)
    for text in parenthetical:
        text = text.strip()
        if text:
            candidates.append(text)
    # 괄호를 제거한 주 텍스트 추출
    main_text = re.sub(r'\([^)]*\)', '', input_color).strip()
    if main_text:
        candidates.append(main_text)
    return candidates

def match_color_fuzzy(input_color):
    """
    입력된 색상 문자열을 분석하여 ALLOWED_COLORS 목록 중 하나로 매핑합니다.
    1) 우선 동의어 매핑(SYNONYM_MAPPING)을 확인합니다.
    2) 동의어 매핑에 없으면, 추출된 후보들에 대해 rapidfuzz를 사용해
       ALLOWED_COLORS와의 유사도 점수를 계산, 무조건 가장 유사한 값을 선택합니다.
    """
    if not input_color:
        return input_color

    candidates = extract_candidates(input_color)
    
    # 1. 동의어 매핑 우선 처리 (괄호 안의 내용부터 확인)
    for candidate in candidates:
        if candidate in SYNONYM_MAPPING:
            mapped = SYNONYM_MAPPING[candidate]
            if mapped in ALLOWED_COLORS:
                return mapped

    # 2. 동의어 매핑이 없으면, 모든 후보에 대해 ALLOWED_COLORS와의 유사도 점수를 계산
    best_match = None
    best_score = -1
    for candidate in candidates:
        result = process.extractOne(candidate, ALLOWED_COLORS, scorer=fuzz.token_set_ratio)
        if result:
            allowed_color, score, _ = result
            if score > best_score:
                best_score = score
                best_match = allowed_color
    return best_match if best_match else "기타"