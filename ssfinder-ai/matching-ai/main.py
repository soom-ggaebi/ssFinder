import os
import sys
import logging
import tempfile
import traceback
import time
from fastapi import FastAPI, Request, HTTPException, Query, Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import List, Dict, Any, Optional, Union
import json
import base64
from io import BytesIO
from PIL import Image

# 캐시 디렉토리 설정 및 최적화
CACHE_DIRS = {
    'TRANSFORMERS_CACHE': '/tmp/transformers_cache',
    'HF_HOME': '/tmp/huggingface_cache',
    'TORCH_HOME': '/tmp/torch_hub_cache',
    'UPLOADS_DIR': '/tmp/uploads'
}

# 환경변수 설정
for key, path in CACHE_DIRS.items():
    os.environ[key] = path
    os.makedirs(path, exist_ok=True)

# 추가 환경변수 최적화
os.environ['HF_HUB_DISABLE_TELEMETRY'] = '1'
os.environ['TRANSFORMERS_VERBOSITY'] = 'error'

# 데이터베이스 관련 환경 변수 (기본값 설정)
os.environ.setdefault('DB_HOST', 'localhost')
os.environ.setdefault('DB_PORT', '3306')
os.environ.setdefault('DB_USER', 'username')
os.environ.setdefault('DB_PASSWORD', 'password')
os.environ.setdefault('DB_NAME', 'foundlost')

# 애플리케이션 환경 설정 (development, production, test)
os.environ.setdefault('APP_ENV', 'development')

# 로깅 설정 개선
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler('/tmp/app.log')
    ]
)
logger = logging.getLogger(__name__)

# 모델 클래스 정의
from pydantic import BaseModel, Field

class SpringMatchRequest(BaseModel):
    category: Optional[int] = None
    title: Optional[str] = None
    color: Optional[str] = None
    content: Optional[str] = None
    detail: Optional[str] = None
    location: Optional[str] = None
    image_url: Optional[str] = None
    threshold: Optional[float] = 0.7

class MatchingResult(BaseModel):
    total_matches: int
    similarity_threshold: float
    matches: List[Dict[str, Any]]

class MatchingResponse(BaseModel):
    success: bool
    message: str
    result: Optional[MatchingResult] = None

# 모델 초기화 (싱글톤으로 로드)
clip_model = None

def get_clip_model(force_reload=False):
    global clip_model
    
    # 모델 로딩 시작 시간 기록
    start_time = time.time()
    
    if clip_model is None or force_reload:
        try:
            # 로깅 및 성능 추적
            logger.info("🔄 CLIP 모델 초기화 시작...")
            
            # 메모리 사용량 기록
            try:
                import psutil
                process = psutil.Process(os.getpid())
                logger.info(f"모델 로드 전 메모리 사용량: {process.memory_info().rss / 1024 / 1024:.2f} MB")
            except ImportError:
                pass
            
            # 모델 로드
            from models.clip_model import KoreanCLIPModel
            clip_model = KoreanCLIPModel()
            
            # 로딩 시간 로깅
            load_time = time.time() - start_time
            logger.info(f"✅ CLIP 모델 로드 완료 (소요시간: {load_time:.2f}초)")
            
            # 메모리 사용량 기록
            try:
                import psutil
                process = psutil.Process(os.getpid())
                logger.info(f"모델 로드 후 메모리 사용량: {process.memory_info().rss / 1024 / 1024:.2f} MB")
            except ImportError:
                pass
            
            return clip_model
        except Exception as e:
            # 상세한 에러 로깅
            logger.error(f"❌ CLIP 모델 초기화 실패: {str(e)}")
            logger.error(f"에러 상세: {traceback.format_exc()}")
            
            # 실패 시 None 반환
            return None
    return clip_model

# 내부적으로 습득물 목록을 가져오는 함수
async def fetch_found_items(limit=100, offset=0):
    try:
        # 실제 데이터베이스에서 데이터 조회
        from db_connector import fetch_found_items as db_fetch_found_items
        found_items = await db_fetch_found_items(limit=limit, offset=offset)
        
        return found_items
    
    except Exception as e:
        logger.error(f"습득물 데이터 조회 중 오류 발생: {str(e)}")
        
        # 오류 발생 시 빈 목록 반환
        return []
    
# FastAPI 애플리케이션 생성
app = FastAPI(
    title="습득물 유사도 검색 API",
    description="한국어 CLIP 모델을 사용하여 사용자 게시글과 습득물 간의 유사도를 계산하는 API",
    version="1.0.0"
)

# CORS 미들웨어 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 애플리케이션 시작 이벤트
@app.on_event("startup")
async def startup_event():

    logger.info("애플리케이션 시작 중...")
    try:
        # 모델 사전 다운로드 (비동기적으로)
        from models.clip_model import preload_clip_model
        preload_clip_model()
        logger.info("모델 사전 다운로드 완료")
        
        # 데이터베이스 연결 테스트
        if os.getenv('APP_ENV') != 'test':
            try:
                from db_connector import get_db_connection
                with get_db_connection() as connection:
                    with connection.cursor() as cursor:
                        cursor.execute("SELECT 1")
                        result = cursor.fetchone()
                        if result:
                            logger.info("✅ 데이터베이스 연결 테스트 성공")
                        else:
                            logger.warning("⚠️ 데이터베이스 연결 테스트 결과 없음")
            except Exception as db_error:
                logger.error(f"❌ 데이터베이스 연결 테스트 실패: {str(db_error)}")
                logger.error(traceback.format_exc())
                
    except Exception as e:
        logger.error(f"시작 중 오류 발생: {str(e)}")
        logger.error(traceback.format_exc())

# 전역 예외 처리
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """
    전역 예외 처리기
    """
    logger.error(f"요청 처리 중 예외 발생: {str(exc)}")
    return JSONResponse(
        status_code=500,
        content={"success": False, "message": f"서버 오류가 발생했습니다: {str(exc)}"}
    )

# 유틸리티 모듈 임포트
from utils.similarity import calculate_similarity, find_similar_items, CATEGORY_WEIGHT, ITEM_NAME_WEIGHT, COLOR_WEIGHT, CONTENT_WEIGHT

# 총 데이터 개수 조회 함수 임포트
from db_connector import count_found_items

# API 엔드포인트 정의 - 양방향 유사도 비교 지원
@app.post("/api/matching/find-similar", response_model=MatchingResponse)
async def find_similar_items_api(
    request: dict,
    threshold: float = Query(0.7, description="유사도 임계값 (0.0 ~ 1.0)"),
    limit: int = Query(10, description="반환할 최대 항목 수"),
    db_limit: int = Query(1000, description="데이터베이스에서 조회할 항목 수")
):
    """
    양방향 유사도 검색 API:
    1. foundItemId가 제공되면 lost_item DB와 비교
    2. lostItemId가 제공되면 found_item DB와 비교
    """
    try:
        # 요청 파라미터 확인 - foundItemId 또는 lostItemId 확인
        found_item_id = request.get('foundItemId')
        lost_item_id = request.get('lostItemId')
        
        logger.info(f"요청 파라미터: foundItemId={found_item_id}, lostItemId={lost_item_id}")
        
        # 요청 데이터 변환
        user_post = {}
        
        # Spring Boot에서 보내는 필드명 매핑
        if 'category' in request:
            user_post['category'] = request['category']
        elif 'itemCategoryId' in request:
            user_post['category'] = request['itemCategoryId']
            
        if 'title' in request:
            user_post['title'] = request['title']
        
        if 'color' in request:
            user_post['color'] = request['color']
        
        if 'detail' in request:
            user_post['content'] = request['detail']
        elif 'content' in request:
            user_post['content'] = request['content']
        
        if 'location' in request:
            user_post['location'] = request['location']
        
        if 'image' in request and request['image']:
            user_post['image_url'] = request['image']
        elif 'image_url' in request and request['image_url']:
            user_post['image_url'] = request['image_url']
            
        if 'threshold' in request and request['threshold']:
            threshold = float(request['threshold'])
        
        # CLIP 모델 로드
        clip_model_instance = get_clip_model()
        
        if clip_model_instance is None:
            return MatchingResponse(
                success=False,
                message="CLIP 모델 로드에 실패했습니다. 잠시 후 다시 시도해주세요.",
                result=None
            )
            
        # 요청 타입에 따라 다른 테이블과 비교
        if found_item_id is not None:
            # foundItemId가 제공된 경우: lost_item DB와 비교
            # 기본 템플릿 post 구성 (템플릿 사용)
            if not user_post:
                # DB에서 해당 found_item 정보 조회를 시도하지만, 오류 발생 시 기본값 사용
                try:
                    from db_connector import get_found_item_info
                    found_item = await get_found_item_info(found_item_id)
                    if found_item:
                        user_post = {
                            'category': found_item.get('item_category_id', 0),
                            'title': found_item.get('title', '') or found_item.get('name', ''),
                            'color': found_item.get('color', ''),
                            'content': found_item.get('content', '') or found_item.get('detail', ''),
                            'location': found_item.get('location', '')
                        }
                except Exception as e:
                    logger.warning(f"ID가 {found_item_id}인 습득물을 찾을 수 없습니다. 기본값을 사용합니다.")
                    # 기본값 설정
                    user_post = {
                        'title': '분실물 검색',
                        'content': '분실물을 검색합니다.'
                    }
                    
            # DB에서 lost_item 데이터 가져오기
            try:
                from db_connector import fetch_lost_items as db_fetch_lost_items
                from db_connector import count_lost_items as db_count_lost_items
                
                # 총 분실물 개수 조회
                total_count = await db_count_lost_items()
                logger.info(f"데이터베이스 내 총 분실물 개수: {total_count}")
                
                # 분실물 목록 가져오기
                compare_items = await db_fetch_lost_items(limit=db_limit)
                
                db_type = "분실물"
            except Exception as e:
                logger.error(f"분실물 데이터 조회 중 오류 발생: {str(e)}")
                # 오류 발생 시 빈 목록 사용
                compare_items = []
                total_count = 0
        else:
            if not user_post:
                # DB에서 해당 lost_item 정보 조회를 시도하지만, 오류 발생 시 기본값 사용
                try:
                    from db_connector import get_lost_item_info
                    lost_item = await get_lost_item_info(lost_item_id)
                    if lost_item:
                        user_post = {
                            'category': lost_item.get('item_category_id', 0),
                            'title': lost_item.get('title', ''),
                            'color': lost_item.get('color', ''),
                            'content': lost_item.get('content', '') or lost_item.get('detail', ''),
                            'location': lost_item.get('location', '')
                        }
                except Exception as e:
                    logger.warning(f"ID가 {lost_item_id}인 분실물을 찾을 수 없습니다. 기본값을 사용합니다.")
                    # 기본값 설정
                    user_post = {
                        'title': '습득물 검색',
                        'content': '습득물을 검색합니다.'
                    }
                    
            # 총 습득물 개수 조회
            total_count = await count_found_items()
            logger.info(f"데이터베이스 내 총 습득물 개수: {total_count}")
            
            # 습득물 목록 가져오기
            compare_items = await fetch_found_items(limit=db_limit, offset=0)
            
            db_type = "습득물"
            
        # 비교할 항목이 없는 경우
        if len(compare_items) == 0:
            return MatchingResponse(
                success=False,
                message=f"{db_type} 데이터를 가져오는데 실패했습니다.",
                result=None
            )
            
        # 데이터베이스에서 가져온 비율 계산
        db_coverage = len(compare_items) / max(1, total_count) * 100
        logger.info(f"총 데이터 중 {db_coverage:.2f}% 검색 ({len(compare_items)}/{total_count})")
        
        # 유사도 계산 시작 시간 기록
        start_time = time.time()
        
        # 유사한 항목 찾기
        similar_items = find_similar_items(user_post, compare_items, threshold, clip_model_instance)
        
        # 유사도 계산 소요 시간
        similarity_time = time.time() - start_time
        logger.info(f"유사도 계산 소요 시간: {similarity_time:.2f}초 (항목당 평균: {similarity_time/max(1, len(compare_items))*1000:.2f}ms)")
        
        # 유사도 세부 정보 로깅
        logger.info("===== 유사도 세부 정보 =====")
        for idx, item in enumerate(similar_items[:5]):  # 상위 5개만 로깅
            logger.info(f"항목 {idx+1}: {item['item'].get('title', '')}")
            logger.info(f"  최종 유사도: {item['similarity']:.4f}")
            
            details = item['details']
            logger.info(f"  텍스트 유사도: {details['text_similarity']:.4f}")
            if details['image_similarity'] is not None:
                logger.info(f"  이미지 유사도: {details['image_similarity']:.4f}")
            
            category_sim = details['details']['category']
            item_name_sim = details['details']['item_name']
            color_sim = details['details']['color']
            content_sim = details['details']['content']
            
            logger.info(f"  카테고리 유사도: {category_sim:.4f} (가중치: {CATEGORY_WEIGHT:.2f})")
            logger.info(f"  물품명 유사도: {item_name_sim:.4f} (가중치: {ITEM_NAME_WEIGHT:.2f})")
            logger.info(f"  색상 유사도: {color_sim:.4f} (가중치: {COLOR_WEIGHT:.2f})")
            logger.info(f"  내용 유사도: {content_sim:.4f} (가중치: {CONTENT_WEIGHT:.2f})")
        logger.info("==========================")
        
        # 결과 제한
        similar_items = similar_items[:limit]
        
        # 응답 구성
        matches = []
        for item in similar_items:
            compare_item = item['item']
            
            # 항목 정보 구성
            item_info = {
                "id": compare_item.get("id", 0),
                "user_id": compare_item.get("user_id", None),
                "item_category_id": compare_item.get("item_category_id", 0),
                "title": compare_item.get("title", "") or compare_item.get("name", ""),
                "color": compare_item.get("color", ""),
                "lost_at": compare_item.get("lost_at", None),
                "found_at": compare_item.get("found_at", None),
                "location": compare_item.get("location", ""),
                "detail": compare_item.get("content", "") or compare_item.get("detail", ""),
                "image": compare_item.get("image", None),
                "status": compare_item.get("status", "ACTIVE"),
                "stored_at": compare_item.get("stored_at", None),
                "majorCategory": compare_item.get("majorCategory", None),
                "minorCategory": compare_item.get("minorCategory", None),
                "management_id": compare_item.get("management_id", None)
            }
            
            # 요청 타입에 따라 응답 구조 조정
            if found_item_id is not None:
                match_item = {
                    "foundItemId": found_item_id,
                    "lostItemId": compare_item.get("id", 0),
                    "item": item_info,
                    "similarity": round(item["similarity"], 4)
                }
            else:
                match_item = {
                    "lostItemId": lost_item_id,
                    "foundItemId": compare_item.get("id", 0),
                    "item": item_info,
                    "similarity": round(item["similarity"], 4)
                }
            
            matches.append(match_item)
        
        # 최종 결과 구성
        result = {
            "total_matches": len(matches),
            "similarity_threshold": threshold,
            "matches": matches,
            "db_coverage_percent": round(db_coverage, 2)
        }

        if matches:
            logger.info("=== 매칭 결과 첫 번째 항목 상세 정보 ===")
            logger.info(f"foundItemId: {matches[0]['foundItemId']}")
            logger.info(f"lostItemId: {matches[0]['lostItemId']}")
            logger.info(f"item ID: {matches[0]['item']['id']}")
            logger.info(f"similarity: {matches[0]['similarity']}")
            logger.info("===================================")
        
        response_data = {
            "success": True,
            "message": f"{len(matches)}개의 유사한 {db_type}을 찾았습니다. (총 {len(compare_items)}개 중 검색)",
            "result": result
        }
        
        # 응답 로깅
        logger.info(f"응답 데이터: {len(matches)}개의 유사한 {db_type} 발견")
        
        return MatchingResponse(**response_data)
    
    except Exception as e:
        logger.error(f"API 호출 중 오류 발생: {str(e)}")
        logger.error(traceback.format_exc())
        
        # 스택 트레이스 반환 (개발용)
        error_response = {
            "success": False,
            "message": f"요청 처리 중 오류가 발생했습니다: {str(e)}",
            "error_detail": traceback.format_exc()
        }
        
        return JSONResponse(status_code=500, content=error_response)

@app.get("/api/matching/test")
async def test_endpoint():
    return {"message": "API가 정상적으로 작동 중입니다."}

@app.get("/api/status")
async def status():
    # CLIP 모델 로드 시도
    model = get_clip_model()
    
    return {
        "status": "ok",
        "models_loaded": model is not None,
        "version": "1.0.0"
    }

# 루트 엔드포인트
@app.get("/")
async def root():
    """
    루트 엔드포인트 - API 정보 제공
    """
    return {
        "app_name": "습득물 유사도 검색 API",
        "version": "1.0.0",
        "description": "한국어 CLIP 모델을 사용하여 사용자 게시글과 습득물 간의 유사도를 계산합니다.",
        "api_endpoint": "/api/matching/find-similar",
        "test_endpoint": "/api/matching/test",
        "status_endpoint": "/api/status"
    }

# 애플리케이션 실행
if __name__ == "__main__":
    import uvicorn
    print("서버 실행 시도 중...")
    try:
        uvicorn.run(
            "main:app", 
            host="0.0.0.0", 
            port=7860,  # 허깅페이스 스페이스에서 사용할 기본 포트
            log_level="info",
            reload=True
        )
    except Exception as e:
        print(f"서버 실행 중 오류 발생: {e}")
        traceback.print_exc()