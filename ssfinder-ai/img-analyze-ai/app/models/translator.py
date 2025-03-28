# 파파고 API를 사용한 번역 서비스

import requests
import urllib.parse
from typing import Optional, Dict, Any
from config import config

class Translator:

    def __init__(self):
        
        self.client_id = config.NAVER_CLIENT_ID
        self.client_secret = config.NAVER_CLIENT_SECRET
        self.use_papago = bool(self.client_id and self.client_secret)
        
    def translate(self, text: str, source: str = "en", target: str = "ko") -> str:

        if not self.use_papago or not text or text.strip() == "":
            return text
            
        # Papago API 엔드포인트
        url = "https://naveropenapi.apigw.ntruss.com/nmt/v1/translation"
        
        # 헤더 설정
        headers = {
            "X-NCP-APIGW-API-KEY-ID": self.client_id,
            "X-NCP-APIGW-API-KEY": self.client_secret,
            "Content-Type": "application/x-www-form-urlencoded"
        }
        
        # 데이터 인코딩
        encoded_text = urllib.parse.quote(text)
        data = f"source={source}&target={target}&text={encoded_text}"
        
        try:
            response = requests.post(url, headers=headers, data=data)
            response.raise_for_status()
            
            result = response.json()
            translated_text = result.get("message", {}).get("result", {}).get("translatedText", "")
            
            return translated_text
        except Exception as e:
            return text  # 오류 발생 시 원본 텍스트 반환
        
    # 분석결과 번역
    def translate_results(self, result_data):

        caption = result_data.get("caption", "")
        title = result_data.get("title", "")
        description = result_data.get("description", "")
        category = result_data.get("category", "")
        color = result_data.get("color", "")
        material = result_data.get("material", "")
        brand = result_data.get("brand", "")
        distinctive_features = result_data.get("distinctive_features", "")
        
        # 카테고리 번역 (매핑 사용)
        translated_category = config.CATEGORY_TRANSLATION.get(category.lower(), category)
        if translated_category == category and self.use_papago:
            # 매핑에 없는 경우 파파고 사용
            translated_category = self.translate(category)
        
        # 색상 번역
        translated_color = self.translate(color) if self.use_papago else color
        
        # 재질 번역
        translated_material = self.translate(material) if self.use_papago else material
        
        # 브랜드 번역 (매핑 사용)
        translated_brand = config.BRAND_TRANSLATION.get(brand.lower() if brand else "", brand if brand else "")
        
        # 제목 생성
        # 색상과 브랜드로 시작
        if translated_brand:
            translated_title = f"{translated_brand} {translated_color} "
        else:
            translated_title = f"{translated_color} "
        
        # 제품명 추가
        title_words = title.lower().split()
        product_found = False
        
        for en_item, ko_item in config.PRODUCT_TRANSLATION.items():
            if en_item in title_words:
                translated_title += ko_item
                product_found = True
                break
        
        # 제품이 없으면 카테고리 사용
        if not product_found:
            translated_title += translated_category
        
        # 특이사항 번역
        translated_features = self.translate(distinctive_features) if self.use_papago and distinctive_features else distinctive_features
        
        # 설명 번역 - 간결한 한국어 형식 사용
        translated_description = f"이 물건은 {translated_material} 재질의 {translated_color} {translated_category}입니다."
        
        # 특이사항이 있으면 추가
        if translated_features and "unknown" not in translated_features.lower() and "none" not in translated_features.lower():
            translated_description += f" 특징은 {translated_features} 입니다."
        
        # 결과 반환
        return {
            "title": translated_title,
            "category": translated_category,
            "color": translated_color,
            "material": translated_material,
            "brand": translated_brand,
            "description": translated_description.strip(),
            "distinctive_features": translated_features
        }