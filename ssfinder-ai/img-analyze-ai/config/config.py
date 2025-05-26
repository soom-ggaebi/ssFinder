import os
from dotenv import load_dotenv

# 환경 변수 로드
load_dotenv()

# 모델 설정
CAPTION_MODEL = "Salesforce/blip-image-captioning-large"
VQA_MODEL = "Salesforce/blip-vqa-capfilt-large"

# 파파고 API 설정
NAVER_CLIENT_ID = os.getenv("NAVER_CLIENT_ID")
NAVER_CLIENT_SECRET = os.getenv("NAVER_CLIENT_SECRET")

# 이미지 처리 설정
MAX_IMAGE_SIZE = 1000

# 카테고리 정의 (영어)
CATEGORIES = [
    "electronics", "clothing", "bag", "wallet", "jewelry", "card", "id", "computer", "cash", "phone",
    "umbrella", "cosmetics", "sports equipment", "books", "others", "documents", "industrial goods", 
    "shopping bag", "musical instrument", "car", "miscellaneous"
]

# 카테고리 한영 매핑
CATEGORY_TRANSLATION = {
    "electronics": "전자기기",
    "clothing": "의류",
    "bag": "가방",
    "wallet": "지갑",
    "jewelry": "보석/액세서리",
    "card": "카드",
    "id": "신분증",
    "computer": "컴퓨터",
    "cash": "현금",
    "phone": "휴대폰",
    "phone case": "휴대폰 케이스",
    "umbrella": "우산",
    "cosmetics": "화장품",
    "sports equipment": "스포츠용품",
    "books": "도서",
    "others": "기타",
    "documents": "서류",
    "industrial goods": "산업용품",
    "shopping bag": "쇼핑백",
    "musical instrument": "악기",
    "car": "자동차",
    "miscellaneous": "기타"
}

# 카테고리 매핑 (캡션의 일반적인 단어를 카테고리로 매핑)
CATEGORY_MAPPING = {
    "umbrella": "umbrella",
    "phone": "phone", 
    "smartphone": "phone",
    "cellphone": "phone",
    "iphone": "phone",
    "wallet": "wallet",
    "bag": "bag",
    "handbag": "bag",
    "backpack": "bag",
    "computer": "computer",
    "laptop": "computer",
    "tablet": "electronics",
    "ipad": "electronics",
    "watch": "jewelry",
    "book": "books",
    "notebook": "books",
    "headphones": "electronics",
    "earphones": "electronics",
    "airpods": "electronics",
    "card": "card",
    "id": "id",
    "key": "others",
    "keys": "others",
    "glasses": "others",
    "sunglasses": "others",
    "camera": "electronics",
    "jewelry": "jewelry"
}

# 색상 목록 정의
COLORS = [
    "red", "blue", "green", "yellow", "black", "white", "gray", "grey", "brown", "purple", 
    "pink", "orange", "silver", "gold", "navy", "beige", "transparent", "multicolor", "teal",
    "turquoise", "maroon", "olive", "cyan", "magenta", "lavender", "indigo", "violet", "tan"
]

# 재질 목록 정의
MATERIALS = [
    "plastic", "metal", "leather", "fabric", "paper", "wood", "glass", "ceramic", "rubber",
    "cotton", "polyester", "nylon", "carbon fiber", "stone", "silicone", "aluminium", "steel",
    "cloth", "textile", "canvas", "denim", "wool", "synthetic", "composite", "unknown"
]

# 브랜드 연관 매핑 (제품 -> 브랜드 연결)
BRAND_ASSOCIATION = {
    # Apple 제품
    "ipad": "apple",
    "iphone": "apple",
    "macbook": "apple",
    "mac": "apple",
    "airpods": "apple",
    "ipod": "apple",
    
    # Samsung 제품
    "galaxy": "samsung",
    
    # 기타 제품들
    "gram": "lg",
    "airmax": "nike",
}

# 브랜드 번역 매핑
BRAND_TRANSLATION = {
    "apple": "애플",
    "samsung": "삼성",
    "lg": "엘지",
    "sony": "소니",
    "nike": "나이키",
    "adidas": "아디다스",
    "puma": "푸마",
    "reebok": "리복",
    "louis vuitton": "루이비통",
    "gucci": "구찌",
    "chanel": "샤넬",
    "prada": "프라다",
    "hermes": "에르메스",
    "coach": "코치",
    "dell": "델",
    "hp": "에이치피",
    "lenovo": "레노버",
    "asus": "아수스",
    "acer": "에이서",
    "timex": "타이맥스",
    "casio": "카시오",
    "seiko": "세이코",
    "citizen": "시티즌",
    "logitech": "로지텍",
    "microsoft": "마이크로소프트",
    "canon": "캐논",
    "nikon": "니콘",
    "jbl": "제이비엘",
    "bose": "보스",
    "sennheiser": "젠하이저",
    "samsonite": "쌤소나이트",
    "tumi": "투미",
    "kindle": "킨들",
    "google": "구글",
    "unknown": "알 수 없음"
}

# 자주 사용되는 제품 이름 한국어 매핑 (제목 생성용)
PRODUCT_TRANSLATION = {
    "phone case": "휴대폰 케이스",
    "phone": "휴대폰", 
    "umbrella": "우산",
    "wallet": "지갑",
    "bag": "가방",
    "laptop": "노트북",
    "computer": "컴퓨터",
    "watch": "시계",
    "book": "책",
    "headphones": "헤드셋",
    "earphones": "이어폰",
    "camera": "카메라",
    "glasses": "안경",
    "tablet": "태블릿",
    "ipad": "아이패드",
    "iphone": "아이폰",
    "airpods": "에어팟"
}

# API 질문 템플릿
QUESTIONS = {
    "category": "What type of item is this? Choose from the following categories: {categories}",
    "color": "What is the main color of this item? Be specific and mention only the color.",
    "material": "What material is this item made of? If unknown, say 'unknown'.",
    "distinctive_features": "What are the distinctive features or unique aspects of this item?",
    "brand": "What is the brand of this item? If unknown, just say 'unknown'."
}