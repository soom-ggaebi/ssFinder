# app/core/producer_detail.py

import pymysql
from config.config import DB_HOST, DB_USER, DB_PASSWORD, DB_NAME

def get_connection():
    """
    MySQL DB에 연결하는 함수
    """
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        db=DB_NAME,
        charset='utf8',
        cursorclass=pymysql.cursors.DictCursor
    )

def update_detail_info(management_id: str, detail_data: dict):
    """
    관리번호(management_id)에 해당하는 found_item 테이블의 상세 정보를 업데이트합니다.
    
    detail_data 예시:
        {
            "status": "RECEIVED", 
            "location": "서울시 강남구", 
            "phone": "010-1234-5678", 
            "detail": "추가 상세 정보..."
        }
    """
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            sql = """
            UPDATE found_item
            SET status = %s,
                location = %s,
                phone = %s,
                detail = %s,
                updated_at = NOW()
            WHERE management_id = %s
            """
            cursor.execute(sql, (
                detail_data.get("status"),
                detail_data.get("location"),
                detail_data.get("phone"),
                detail_data.get("detail"),
                management_id
            ))
            conn.commit()
            print(f"Detail info for management_id {management_id} updated successfully.")
    except Exception as e:
        print(f"Error updating detail info for management_id {management_id}: {e}")
    finally:
        conn.close()

# 테스트 실행 (필요 시)
if __name__ == "__main__":
    sample_detail = {
        "status": "RECEIVED",
        "location": "서울시 강남구",
        "phone": "010-1234-5678",
        "detail": "테스트 상세 정보입니다."
    }
    update_detail_info("F2024082800004004", sample_detail)
