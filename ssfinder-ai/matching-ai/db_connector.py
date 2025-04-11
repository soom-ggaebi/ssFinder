import os
import logging
import traceback
import pymysql
from pymysql.cursors import DictCursor
from contextlib import contextmanager

# 로깅 설정
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 데이터베이스 연결 설정
DB_CONFIG = {
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 3306)),
    'user': os.getenv('DB_USER', 'username'),
    'password': os.getenv('DB_PASSWORD', 'password'),
    'db': os.getenv('DB_NAME', 'foundlost'),
    'charset': 'utf8mb4',
    'cursorclass': DictCursor
}

@contextmanager
def get_db_connection():
    connection = None
    try:
        connection = pymysql.connect(**DB_CONFIG)
        logger.info("데이터베이스 연결 성공")
        yield connection
    except Exception as e:
        logger.error(f"데이터베이스 연결 오류: {str(e)}")
        logger.error(traceback.format_exc())
        raise
    finally:
        if connection:
            connection.close()
            logger.debug("데이터베이스 연결 종료")

async def fetch_found_items(limit=100, offset=0):
    found_items = []
    
    try:
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                query = """
                SELECT f.id, f.user_id, f.item_category_id, f.name as title, f.color, 
                       f.detail as content, f.location, f.image, f.status, f.found_at as lost_at, 
                       f.created_at, f.management_id, f.stored_at,
                       ic.name as category_name,
                       ic.level as majorCategory,  # major_category 대신 level 사용
                       ic.name as minorCategory
                FROM found_item f
                LEFT JOIN item_category ic ON f.item_category_id = ic.id
                WHERE f.status IN ('STORED', 'RECEIVED', 'TRANSFERRED')
                ORDER BY f.created_at DESC
                LIMIT %s OFFSET %s
                """
                
                cursor.execute(query, (limit, offset))
                rows = cursor.fetchall()
                
                # 조회 결과를 API 응답 형식에 맞게 변환
                for row in rows:
                    found_item = {
                        "id": row["id"],
                        "user_id": row["user_id"],
                        "item_category_id": row["item_category_id"],
                        "title": row["title"],  # name 컬럼을 title로 매핑
                        "color": row["color"],
                        "content": row["content"],  # detail 컬럼을 content로 매핑
                        "location": row["location"],
                        "image": row["image"],
                        "status": row["status"],
                        "lost_at": row["lost_at"],
                        "stored_at": row["stored_at"],
                        "management_id": row["management_id"],
                        "category": row["category_name"],
                        "majorCategory": row["majorCategory"],
                        "minorCategory": row["minorCategory"]
                    }
                    found_items.append(found_item)
                
                logger.info(f"{len(found_items)}개의 습득물 데이터 조회 완료")
    
    except Exception as e:
        logger.error(f"습득물 데이터 조회 중 오류 발생: {str(e)}")
        logger.error(traceback.format_exc())
    
    return found_items

# 습득물 데이터 개수 조회 함수
async def count_found_items():
    try:
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                # status가 'STORED'인 항목만 조회
                query = "SELECT COUNT(*) as total FROM found_item WHERE status IN ('STORED', 'RECEIVED', 'TRANSFERRED')"
                cursor.execute(query)
                result = cursor.fetchone()
                total_count = result["total"]
                logger.info(f"총 습득물 데이터 개수: {total_count}")
                return total_count
    
    except Exception as e:
        logger.error(f"습득물 데이터 개수 조회 중 오류 발생: {str(e)}")
        logger.error(traceback.format_exc())
        return 0

# 분실물 목록을 가져오는 함수
async def fetch_lost_items(limit=100, offset=0):
    try:
        # 환경변수 확인 - 테스트 모드인 경우 샘플 데이터 반환
        if os.getenv('APP_ENV') == 'test':
            logger.info("테스트 모드: 샘플 데이터 사용")
            # 예시 데이터 - 테스트용
            sample_lost_items = [
                {
                    "id": 1,
                    "item_category_id": 1,
                    "title": "검정 가죽 지갑",
                    "color": "검정색",
                    "content": "강남역 근처에서 검정색 가죽 지갑을 잃어버렸습니다.",
                    "location": "강남역",
                    "image": None,
                    "category": "지갑"
                },
                {
                    "id": 2,
                    "item_category_id": 1,
                    "title": "갈색 가죽 지갑",
                    "color": "갈색",
                    "content": "서울대입구역 근처에서 갈색 가죽 지갑을 잃어버렸습니다.",
                    "location": "서울대입구역",
                    "image": None,
                    "category": "지갑"
                }
            ]
            return sample_lost_items
        
        # 실제 데이터베이스에서 데이터 조회
        logger.info(f"데이터베이스에서 분실물 데이터 조회 중 (limit: {limit}, offset: {offset})...")
        
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                # lost_item 테이블에서 분실물 데이터 조회
                query = """
                SELECT l.id, l.user_id, l.item_category_id, l.title, l.color, 
                       l.lost_at, l.location, l.detail as content, l.image, 
                       l.status,
                       ic.level as majorCategory, 
                       ic.name as minorCategory
                FROM lost_item l
                LEFT JOIN item_category ic ON l.item_category_id = ic.id
                WHERE l.status = 'LOST'
                ORDER BY l.id DESC
                LIMIT %s OFFSET %s
                """
                cursor.execute(query, (limit, offset))
                result = cursor.fetchall()  # DictCursor를 사용하므로 딕셔너리로 반환됨
                
                logger.info(f"데이터베이스에서 {len(result)}개의 분실물 데이터 조회 완료")
                return result
    
    except Exception as e:
        logger.error(f"분실물 데이터 조회 중 오류 발생: {str(e)}")
        logger.error(traceback.format_exc())
        
        # 오류 발생 시 빈 목록 반환
        return []

# 분실물 총 개수를 조회하는 함수
async def count_lost_items():
    try:
        # 테스트 모드인 경우 샘플 데이터 개수 반환
        if os.getenv('APP_ENV') == 'test':
            return 2  # 샘플 데이터 개수
        
        # 실제 데이터베이스에서 데이터 개수 조회
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                query = "SELECT COUNT(*) as total FROM lost_item WHERE status = 'LOST'"
                cursor.execute(query)
                result = cursor.fetchone()
                # DictCursor를 사용하므로 딕셔너리로 반환됨
                count = result["total"]
                return count
    
    except Exception as e:
        logger.error(f"분실물 데이터 개수 조회 중 오류 발생: {str(e)}")
        logger.error(traceback.format_exc())
        
        # 오류 발생 시 0 반환
        return 0

# 특정 ID의 습득물 정보를 가져오는 함수
async def get_found_item_info(found_item_id):
    try:
        if os.getenv('APP_ENV') == 'test':
            return {
                "id": found_item_id,
                "item_category_id": 1,
                "name": "검정 가죽 지갑",
                "color": "검정색",
                "detail": "강남역 근처에서 검정색 가죽 지갑을 발견했습니다.",
                "location": "강남역"
            }
            
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                query = """
                SELECT f.id, f.user_id, f.item_category_id, f.name, f.color, 
                       f.found_at, f.location, f.detail, f.image, 
                       f.status, f.stored_at, f.management_id,
                       ic.major_category AS majorCategory, 
                       ic.name AS minorCategory
                FROM found_item f
                LEFT JOIN item_category ic ON f.item_category_id = ic.id
                WHERE f.id = %s
                """
                cursor.execute(query, (found_item_id,))
                return cursor.fetchone()
    except Exception as e:
        logger.error(f"습득물 정보 조회 중 오류 발생: {str(e)}")
        logger.error(traceback.format_exc())
        return None

# 특정 ID의 분실물 정보를 가져오는 함수
async def get_lost_item_info(lost_item_id):
    try:
        if os.getenv('APP_ENV') == 'test':
            return {
                "id": lost_item_id,
                "item_category_id": 1,
                "title": "검정 가죽 지갑",
                "color": "검정색",
                "detail": "강남역 근처에서 검정색 가죽 지갑을 잃어버렸습니다.",
                "location": "강남역"
            }
            
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                query = """
                SELECT l.id, l.user_id, l.item_category_id, l.title, l.color, 
                       l.lost_at, l.location, l.detail, l.image, 
                       l.status,
                       ic.major_category AS majorCategory, 
                       ic.name AS minorCategory
                FROM lost_item l
                LEFT JOIN item_category ic ON l.item_category_id = ic.id
                WHERE l.id = %s
                """
                cursor.execute(query, (lost_item_id,))
                return cursor.fetchone()
    except Exception as e:
        logger.error(f"분실물 정보 조회 중 오류 발생: {str(e)}")
        logger.error(traceback.format_exc())
        return None

# 특정 ID의 습득물 정보를 가져오는 함수
async def fetch_found_item_by_id(found_item_id):
    try:
        # 실제 데이터베이스에서 데이터 조회
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                query = """
                SELECT f.id, f.user_id, f.item_category_id, f.name as title, f.color, 
                       f.found_at, f.location, f.detail as content, f.image, 
                       f.status, f.stored_at, f.management_id,
                       ic.major_category as majorCategory, 
                       ic.name as minorCategory
                FROM found_item f
                LEFT JOIN item_category ic ON f.item_category_id = ic.id
                WHERE f.id = %s
                """
                cursor.execute(query, (found_item_id,))
                item = cursor.fetchone()
                
                if item:
                    return item
                else:
                    return None
    
    except Exception as e:
        logger.error(f"습득물 조회 중 오류 발생: {str(e)}")
        
        # 오류 발생 시 None 반환
        return None

# 특정 ID의 분실물 정보를 가져오는 함수 - 수정
async def fetch_lost_item_by_id(lost_item_id):
    try:
        # 실제 데이터베이스에서 데이터 조회
        with get_db_connection() as connection:
            with connection.cursor() as cursor:
                query = """
                SELECT l.id, l.user_id, l.item_category_id, l.title, l.color, 
                       l.lost_at, l.location, l.detail as content, l.image, 
                       l.status,
                       ic.major_category as majorCategory, 
                       ic.name as minorCategory
                FROM lost_item l
                LEFT JOIN item_category ic ON l.item_category_id = ic.id
                WHERE l.id = %s
                """
                cursor.execute(query, (lost_item_id,))
                item = cursor.fetchone()
                
                if item:
                    return item
                else:
                    return None
    
    except Exception as e:
        logger.error(f"분실물 조회 중 오류 발생: {str(e)}")
        
        # 오류 발생 시 None 반환
        return None