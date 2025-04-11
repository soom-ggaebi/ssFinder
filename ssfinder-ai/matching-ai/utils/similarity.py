"""
유사도 계산 및 관련 유틸리티 함수
Kiwi 형태소 분석기를 사용하여 한국어 텍스트 분석 개선
"""
import os
import sys
import logging
import numpy as np
import re
from collections import Counter
from kiwipiepy import Kiwi

# 로깅 설정
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Kiwi 형태소 분석기 초기화
kiwi = Kiwi()

# 설정 값 (환경변수 또는 기본값)
SIMILARITY_THRESHOLD = float(os.getenv('SIMILARITY_THRESHOLD', '0.6'))
TEXT_WEIGHT = float(os.getenv('TEXT_WEIGHT', '0.7'))
IMAGE_WEIGHT = float(os.getenv('IMAGE_WEIGHT', '0.3'))
CATEGORY_WEIGHT = float(os.getenv('CATEGORY_WEIGHT', '0.5'))
ITEM_NAME_WEIGHT = float(os.getenv('ITEM_NAME_WEIGHT', '0.3'))
COLOR_WEIGHT = float(os.getenv('COLOR_WEIGHT', '0.1'))
CONTENT_WEIGHT = float(os.getenv('CONTENT_WEIGHT', '0.1'))

def preprocess_text(text):
    """
    텍스트 전처리 함수
    """
    if not text:
        return ""

    if not isinstance(text, str):
        text = str(text)
        
    # 소문자 변환 (영어의 경우)
    text = text.lower()
    
    # 불필요한 공백 제거
    text = re.sub(r'\s+', ' ', text).strip()
    
    # 특수 문자 제거 (단, 한글, 영문, 숫자는 유지)
    text = re.sub(r'[^\w\s가-힣ㄱ-ㅎㅏ-ㅣ]', ' ', text)
    
    return text

def extract_keywords(text):
    """
    Kiwi 형태소 분석기를 사용하여 텍스트에서 중요 키워드 추출
    """
    if not text:
        return []
    
    # 텍스트 전처리
    processed_text = preprocess_text(text)
    
    try:
        # Kiwi 형태소 분석 수행
        result = kiwi.analyze(processed_text)
        
        # 중요 키워드 추출 (명사, 형용사 등)
        keywords = []
        for token in result[0][0]:
            # NNG: 일반명사, NNP: 고유명사, VA: 형용사, VV: 동사, SL: 외국어(영어 등)
            if token.tag in ['NNG', 'NNP', 'VA', 'SL']:
                # 한 글자 명사는 중요도 낮을 수 있어 필터링 (선택적)
                if len(token.form) > 1 or token.tag in ['SL']:
                    keywords.append(token.form)
        
        logger.debug(f"키워드 추출 결과: {keywords}")
        return keywords
    
    except Exception as e:
        logger.warning(f"형태소 분석 오류: {str(e)}, 기본 분리 방식으로 대체")
        # 오류 발생 시 기본 방식으로 대체
        words = processed_text.split()
        return words

def calculate_text_similarity(text1, text2, weights=None):
    """
    두 텍스트 간의 유사도 계산 (Kiwi 형태소 분석 활용)
    개선된 버전: 정확한 일치 및 포함 관계도 고려
    """
    if not text1 or not text2:
        return 0.0
    
    # 원본 텍스트 전처리
    clean_text1 = preprocess_text(text1)
    clean_text2 = preprocess_text(text2)
    
    # 1. 정확한 일치 검사
    if clean_text1.lower() == clean_text2.lower():
        return 1.0
    
    # 2. 포함 관계 검사 (짧은 텍스트가 긴 텍스트에 포함됨)
    if clean_text1.lower() in clean_text2.lower() or clean_text2.lower() in clean_text1.lower():
        # 길이 비율에 따라 유사도 계산 (최소 0.7)
        len_ratio = min(len(clean_text1), len(clean_text2)) / max(len(clean_text1), len(clean_text2))
        return max(0.7, 0.7 + 0.3 * len_ratio)  # 0.7~1.0 사이 값
    
    # 기본 가중치 설정
    if weights is None:
        weights = {
            'common_words': 0.7,   # 공통 단어 비율의 가중치
            'length_ratio': 0.15,  # 길이 유사성 가중치
            'word_order': 0.15     # 단어 순서 유사성 가중치
        }
    
    # 텍스트에서 키워드 추출 (Kiwi 형태소 분석기 사용)
    keywords1 = extract_keywords(text1)
    keywords2 = extract_keywords(text2)
    
    if not keywords1 or not keywords2:
        # 키워드가 없으면 원본 텍스트의 유사도 계산
        jaccard_sim = calculate_jaccard_similarity(clean_text1, clean_text2)
        return max(0.1, jaccard_sim)  # 최소 0.1 유사도 부여
    
    # 3. 공통 단어 비율 계산 (개선)
    common_words = set(keywords1) & set(keywords2)
    
    if common_words:
        # 공통 단어가 있을 경우 비율 계산
        common_ratio = len(common_words) / min(len(set(keywords1)), len(set(keywords2)))
        
        # 주요 키워드가 공통되는 경우 가중치 추가
        important_keywords = [w for w in common_words 
                             if len(w) > 1 and not w.isdigit()]
        if important_keywords:
            common_ratio = max(common_ratio, 0.5 + 0.3 * (len(important_keywords) / len(common_words)))
    else:
        # 공통 키워드가 없으면 자카드 유사도 계산 (낮은 값)
        common_ratio = calculate_jaccard_similarity(clean_text1, clean_text2) * 0.5
    
    # 4. 텍스트 길이 유사도
    length_ratio = min(len(keywords1), len(keywords2)) / max(1, max(len(keywords1), len(keywords2)))
    
    # 5. 단어 순서 유사도 (선택적)
    word_order_sim = 0.0
    if common_words:
        # 공통 단어의 위치 차이 기반 유사도
        positions1 = {word: i for i, word in enumerate(keywords1) if word in common_words}
        positions2 = {word: i for i, word in enumerate(keywords2) if word in common_words}
        
        if positions1 and positions2:
            common_words_positions = set(positions1.keys()) & set(positions2.keys())
            if common_words_positions:
                pos_diff_sum = sum(abs(positions1[word] - positions2[word]) 
                                 for word in common_words_positions)
                max_diff = len(keywords1) + len(keywords2)
                word_order_sim = 1.0 - min(1.0, (pos_diff_sum / max(1, max_diff)))
    
    # 가중치 적용하여 최종 유사도 계산
    similarity = (
        weights['common_words'] * common_ratio + 
        weights['length_ratio'] * length_ratio + 
        weights['word_order'] * word_order_sim
    )
    
    # 최소 유사도 보장 (키워드가 있다면)
    if common_words:
        similarity = max(similarity, 0.1 + 0.2 * len(common_words) / max(len(keywords1), len(keywords2)))
    
    return min(1.0, max(0.0, similarity))

# 자카드 유사도 계산 함수 추가
def calculate_jaccard_similarity(text1, text2):
    """
    두 텍스트 간의 자카드 유사도 계산
    """
    set1 = set(text1.lower().split())
    set2 = set(text2.lower().split())
    
    if not set1 or not set2:
        return 0.0
    
    intersection = len(set1 & set2)
    union = len(set1 | set2)
    
    return intersection / max(1, union)

def calculate_category_similarity(category1, category2):
    """
    두 카테고리 간의 유사도 계산
    """
    # None 또는 빈 값 처리
    if not category1 or not category2:
        return 0.0
    
    # 정수형 ID인 경우 직접 비교
    if isinstance(category1, int) and isinstance(category2, int):
        return 1.0 if category1 == category2 else 0.0
    
    # 문자열로 변환
    cat1 = str(category1).strip()
    cat2 = str(category2).strip()
    
    # 완전 일치 확인
    if cat1.lower() == cat2.lower():
        return 1.0
    
    # 카테고리 전처리
    cat1_processed = preprocess_text(cat1)
    cat2_processed = preprocess_text(cat2)
    
    # 전처리 후 일치 확인
    if cat1_processed.lower() == cat2_processed.lower():
        return 1.0
    
    # 포함 관계 확인 (예: '지갑'과 '가죽 지갑')
    if cat1_processed.lower() in cat2_processed.lower() or cat2_processed.lower() in cat1_processed.lower():
        # 길이 비율에 따라 유사도 조정
        len_ratio = min(len(cat1_processed), len(cat2_processed)) / max(len(cat1_processed), len(cat2_processed))
        return max(0.8, len_ratio)  # 최소 0.8 유사도
    
    # 키워드 추출 및 공통 단어 확인
    keywords1 = set(extract_keywords(cat1))
    keywords2 = set(extract_keywords(cat2))
    
    # 공통 키워드가 있는 경우
    common_keywords = keywords1 & keywords2
    if common_keywords:
        # 공통 키워드 비율에 따라 유사도 계산
        common_ratio = len(common_keywords) / min(len(keywords1), len(keywords2)) if keywords1 and keywords2 else 0
        return max(0.5, common_ratio)  # 최소 0.5 유사도
    
    # '기타' 카테고리 처리
    if '기타' in cat1 or '기타' in cat2:
        return 0.3  # 기타 카테고리는 약한 연관성
    
    # 최종적으로 텍스트 유사도 계산
    return calculate_text_similarity(cat1, cat2)

def calculate_similarity(user_post, lost_item, clip_model=None):
    """
    사용자 게시글과 습득물 항목 간의 종합 유사도 계산
    Spring Boot와 호환되도록 필드명 매핑 수정
    """
    # 텍스트 유사도 계산
    text_similarities = {}
    
    # 필드 존재 여부 검사 및 로깅
    logger.info(f"==== 유사도 계산 시작 ====")
    
    # 1. 카테고리 유사도 - ID만 사용하도록 수정
    category_sim = 0.0
    # 사용자 카테고리 필드: 'category' 또는 'itemCategoryId'
    user_category_id = None
    if 'category' in user_post and user_post['category'] is not None:
        user_category_id = user_post['category']
    elif 'itemCategoryId' in user_post and user_post['itemCategoryId'] is not None:
        user_category_id = user_post['itemCategoryId']
    
    # 습득물 카테고리 필드: 'item_category_id'만 사용
    lost_category_id = None
    if 'item_category_id' in lost_item and lost_item['item_category_id'] is not None:
        lost_category_id = lost_item['item_category_id']
    
    # 카테고리 정보 로깅
    logger.info(f"카테고리 ID 비교: 사용자({user_category_id}) vs 습득물({lost_category_id})")
    
    # 카테고리 ID 유사도 계산 - 정확히 같은 ID인 경우만 일치
    if user_category_id is not None and lost_category_id is not None:

        try:
            # 숫자로 변환하여 비교
            user_category_id = int(user_category_id)
            lost_category_id = int(lost_category_id)
            category_sim = 1.0 if user_category_id == lost_category_id else 0.0
            logger.info(f"카테고리 ID 일치 여부: {category_sim}")
        except (ValueError, TypeError):
            logger.warning(f"카테고리 ID를 숫자로 변환할 수 없음: {user_category_id}, {lost_category_id}")
            category_sim = 0.0
    text_similarities['category'] = category_sim
    
    # 2. 물품명 유사도 (사용자 측이 없을 경우 카테고리나 검색어에서 추출)
    item_name_sim = 0.0
    user_item_name = None
    
    # 사용자 물품명: title, search_keyword, content 중에서 가져오기
    if 'title' in user_post and user_post['title']:
        user_item_name = user_post['title']
    elif 'search_keyword' in user_post and user_post['search_keyword']:
        # 검색 키워드가 있으면 사용
        user_item_name = user_post['search_keyword']
    elif 'content' in user_post and user_post['content']:
        # 내용에서 첫 문장이나 키워드 추출
        content = user_post['content']
        # 첫 10단어 추출 (또는 적절한 길이)
        words = content.split()[:10]
        if words:
            user_item_name = ' '.join(words)
    
    # 습득물 물품명: name 또는 title에서 가져오기
    lost_item_name = None
    if 'name' in lost_item and lost_item['name']:
        lost_item_name = lost_item['name']
    elif 'title' in lost_item and lost_item['title']:
        lost_item_name = lost_item['title']
    
    logger.info(f"물품명 필드: 사용자({user_item_name}) vs 습득물({lost_item_name})")
    
    # 물품명 유사도 계산
    if user_item_name and lost_item_name:
        # 전처리 적용
        user_item_name_clean = preprocess_text(str(user_item_name))
        lost_item_name_clean = preprocess_text(str(lost_item_name))
        
        # 기본 유사도 계산
        item_name_sim = calculate_text_similarity(user_item_name_clean, lost_item_name_clean)
        
        # 완전 일치하거나 포함 관계인 경우 가중치 부여
        if user_item_name_clean.lower() == lost_item_name_clean.lower():
            item_name_sim = 1.0  # 완전 일치
            logger.info("물품명 완전 일치")
        elif user_item_name_clean.lower() in lost_item_name_clean.lower() or lost_item_name_clean.lower() in user_item_name_clean.lower():
            item_name_sim = 0.8  # 부분 포함
            logger.info("물품명 포함 관계 감지")
    elif user_item_name is None and lost_item_name:
        # 사용자 물품명이 없고 습득물 물품명만 있는 경우
        # 카테고리나 색상이 일치하면 최소 유사도 부여
        if category_sim > 0.5 or ('color' in user_post and 'color' in lost_item and 
                                 preprocess_text(user_post['color']).lower() == preprocess_text(lost_item['color']).lower()):
            item_name_sim = 0.3  # 최소 유사도 부여
            logger.info("사용자 물품명 없음, 카테고리/색상 유사성 기반 최소 유사도 부여")
        else:
            logger.warning(f"사용자 물품명 누락, 유사도 0")
    else:
        logger.warning(f"물품명 비교 불가: 사용자({user_item_name}) 또는 습득물({lost_item_name}) 물품명 누락")
    
    text_similarities['item_name'] = item_name_sim
    
    # 3. 색상 유사도
    color_sim = 0.0
    # 색상 필드는 동일하게 'color'
    user_color = user_post.get('color', '')
    lost_color = lost_item.get('color', '')
    
    logger.info(f"색상 비교: 사용자({user_color}) vs 습득물({lost_color})")
    
    # 색상 유사도 계산
    if user_color and lost_color:
        # 색상 키워드 추출
        user_color_clean = preprocess_text(str(user_color))
        lost_color_clean = preprocess_text(str(lost_color))
        
        # 완전 일치 검사
        if user_color_clean.lower() == lost_color_clean.lower():
            color_sim = 1.0
            logger.info("색상 완전 일치")
        else:
            # 공통 키워드 검사
            user_color_keywords = extract_keywords(user_color)
            lost_color_keywords = extract_keywords(lost_color)
            common_keywords = set(user_color_keywords) & set(lost_color_keywords)
            
            if common_keywords:
                color_sim = 0.8
                logger.info(f"색상 공통 키워드: {common_keywords}")
            else:
                color_sim = calculate_text_similarity(user_color, lost_color)
                logger.info(f"색상 기본 유사도: {color_sim}")
    else:
        logger.warning(f"색상 누락: 사용자({user_color}) 또는 습득물({lost_color})")
    
    text_similarities['color'] = color_sim
    
    # 4. 내용 유사도
    content_sim = 0.0
    
    # 모든 가능한 내용 필드 검사
    possible_content_fields_user = ['detail', 'content', 'description']
    possible_content_fields_lost = ['detail', 'content', 'description']
    
    # 사용자 내용 필드 찾기
    user_content = None
    user_content_field = None
    for field in possible_content_fields_user:
        if field in user_post and user_post[field]:
            user_content = user_post[field]
            user_content_field = field
            break
    
    # 습득물 내용 필드 찾기
    lost_content = None
    lost_content_field = None
    for field in possible_content_fields_lost:
        if field in lost_item and lost_item[field]:
            lost_content = lost_item[field]
            lost_content_field = field
            break
    
    logger.info(f"내용 필드: 사용자({user_content_field}) vs 습득물({lost_content_field})")
    
    # 내용 유사도 계산
    if user_content and lost_content:
        # 내용의 길이가 짧을 수 있으므로 전처리 후 키워드 추출에 중점
        user_content_keywords = extract_keywords(user_content)
        lost_content_keywords = extract_keywords(lost_content)
        
        logger.info(f"내용 키워드 수: 사용자({len(user_content_keywords)}개) vs 습득물({len(lost_content_keywords)}개)")
        
        if user_content_keywords and lost_content_keywords:
            # 공통 키워드 비율 계산
            common_keywords = set(user_content_keywords) & set(lost_content_keywords)
            if common_keywords:
                common_ratio = len(common_keywords) / min(len(user_content_keywords), len(lost_content_keywords))
                logger.info(f"내용 공통 키워드: {len(common_keywords)}개, 공통 비율: {common_ratio:.4f}")
                
                # 공통 키워드가 많을수록 유사도 증가
                if common_ratio >= 0.5:  # 50% 이상 공통 키워드
                    content_sim = max(0.7, common_ratio)
                    logger.info(f"내용 높은 공통 비율: {content_sim:.4f}")
                else:
                    text_sim = calculate_text_similarity(user_content, lost_content)
                    content_sim = max(text_sim, common_ratio)
                    logger.info(f"내용 기본 유사도: {text_sim:.4f}, 최종: {content_sim:.4f}")
            else:
                content_sim = calculate_text_similarity(user_content, lost_content)
                logger.info(f"내용 공통 키워드 없음, 기본 유사도: {content_sim:.4f}")
        else:
            content_sim = calculate_text_similarity(user_content, lost_content)
            logger.info(f"내용 키워드 추출 실패, 기본 유사도: {content_sim:.4f}")
    else:
        logger.warning(f"내용 누락: 사용자({user_content is not None}) 또는 습득물({lost_content is not None})")
    
    text_similarities['content'] = content_sim
    
    # 가중치 조정
    ADJ_CATEGORY_WEIGHT = 0.35
    ADJ_ITEM_NAME_WEIGHT = 0.35
    ADJ_COLOR_WEIGHT = 0.15
    ADJ_CONTENT_WEIGHT = 0.15
    
    # 텍스트 종합 유사도 계산 (가중치 적용)
    total_text_similarity = (
        ADJ_CATEGORY_WEIGHT * category_sim +
        ADJ_ITEM_NAME_WEIGHT * item_name_sim +
        ADJ_COLOR_WEIGHT * color_sim +
        ADJ_CONTENT_WEIGHT * content_sim
    )
    
    # 최종 유사도는 텍스트 유사도만 사용
    final_similarity = total_text_similarity
    
    # 유사도 계산 결과 로깅
    logger.info(f"유사도 계산 결과: 카테고리({category_sim:.4f}*{ADJ_CATEGORY_WEIGHT}) + 물품명({item_name_sim:.4f}*{ADJ_ITEM_NAME_WEIGHT}) + 색상({color_sim:.4f}*{ADJ_COLOR_WEIGHT}) + 내용({content_sim:.4f}*{ADJ_CONTENT_WEIGHT}) = {final_similarity:.4f}")
    logger.info(f"==== 유사도 계산 종료 ====")
    
    # 세부 유사도 정보
    similarity_details = {
        'text_similarity': total_text_similarity,
        'image_similarity': None,  # 이미지 유사도 사용 안함
        'final_similarity': final_similarity,
        'details': text_similarities
    }
    
    return final_similarity, similarity_details

def find_similar_items(user_post, lost_items, threshold=SIMILARITY_THRESHOLD, clip_model=None):
    """
    사용자 게시글과 유사한 습득물 목록 찾기
    
    Args:
        user_post (dict): 사용자 게시글 정보
        lost_items (list): 습득물 데이터 목록
        threshold (float): 유사도 임계값 (기본값: config에서 설정)
        clip_model (KoreanCLIPModel, optional): CLIP 모델 인스턴스
        
    Returns:
        list: 유사도가 임계값 이상인 습득물 목록 (유사도 높은 순)
    """
    similar_items = []
    
    logger.info(f"사용자 게시글과 {len(lost_items)}개 습득물 비교 중...")
    
    for item in lost_items:
        similarity, details = calculate_similarity(user_post, item, clip_model)
        
        if similarity >= threshold:
            similar_items.append({
                'item': item,
                'similarity': similarity,
                'details': details
            })
    
    # 유사도 높은 순으로 정렬
    similar_items.sort(key=lambda x: x['similarity'], reverse=True)
    
    logger.info(f"유사도 {threshold} 이상인 습득물 {len(similar_items)}개 발견")
    
    return similar_items

# 모듈 테스트용 코드
if __name__ == "__main__":
    # 텍스트 유사도 테스트
    text1 = "검은색 가죽 지갑을 잃어버렸습니다."
    text2 = "검정 가죽 지갑을 찾았습니다."
    text3 = "노트북을 분실했습니다."
    
    # 키워드 추출 테스트
    print("[ 키워드 추출 테스트 ]")
    print(f"텍스트 1: '{text1}'")
    print(f"추출된 키워드: {extract_keywords(text1)}")
    print(f"텍스트 2: '{text2}'")
    print(f"추출된 키워드: {extract_keywords(text2)}")
    
    # 유사도 테스트
    sim12 = calculate_text_similarity(text1, text2)
    sim13 = calculate_text_similarity(text1, text3)
    
    print("\n[ 유사도 테스트 ]")
    print(f"텍스트 1-2 유사도: {sim12:.4f}")
    print(f"텍스트 1-3 유사도: {sim13:.4f}")
    
    # 카테고리 유사도 테스트
    cat1 = "지갑"
    cat2 = "가방/지갑"
    cat3 = "기타"
    
    cat_sim12 = calculate_category_similarity(cat1, cat2)
    cat_sim13 = calculate_category_similarity(cat1, cat3)
    
    print("\n[ 카테고리 유사도 테스트 ]")
    print(f"카테고리 1-2 유사도: {cat_sim12:.4f}")
    print(f"카테고리 1-3 유사도: {cat_sim13:.4f}")