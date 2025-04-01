"""
대시보드 관련 API 라우트
데이터 수집 상태 및 통계를 제공하는 엔드포인트를 포함합니다.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
import pymysql
from pymysql.cursors import DictCursor
import logging

from config.config import DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME

logger = logging.getLogger(__name__)

router = APIRouter(
    prefix="/dashboard",
    tags=["대시보드"],
    responses={404: {"description": "Not found"}},
)

def get_db_connection():
    """데이터베이스 연결 획득"""
    try:
        connection = pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            charset='utf8mb4',
            use_unicode=True,
            cursorclass=DictCursor
        )
        return connection
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"데이터베이스 연결 실패: {str(e)}")

@router.get("/summary")
async def get_summary():
    """
    데이터 수집 요약 정보 제공
    총 아이템 수, 오늘 수집된 아이템 수, 카테고리별 통계 등을 반환합니다.
    """
    conn = get_db_connection()
    try:
        stats = {}

        # 총 아이템 수
        with conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) as total FROM found_item")
            result = cursor.fetchone()
            stats["total_items"] = result["total"]

        # 오늘 수집된 아이템 수
        today = datetime.utcnow().date()
        with conn.cursor() as cursor:
            cursor.execute(
                "SELECT COUNT(*) as today_count FROM found_item WHERE DATE(created_at) = %s",
                (today,)
            )
            result = cursor.fetchone()
            stats["today_items"] = result["today_count"]

        # 카테고리별 통계
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT c.name, COUNT(*) as count
                FROM found_item f
                JOIN item_category c ON f.item_category_id = c.id
                GROUP BY c.name
                ORDER BY count DESC
                LIMIT 10
            """)
            stats["categories"] = cursor.fetchall()

        # 색상별 통계
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT color, COUNT(*) as count
                FROM found_item
                WHERE color IS NOT NULL
                GROUP BY color
                ORDER BY count DESC
            """)
            stats["colors"] = cursor.fetchall()

        return {
            "status": "success",
            "data": stats
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"통계 데이터 조회 실패: {str(e)}")
    finally:
        conn.close()

@router.get("/recent")
async def get_recent_items(limit: int = Query(10, ge=1, le=100)):
    """
    최근 수집된 아이템 목록 제공
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT f.id, f.management_id, f.name, f.color, f.stored_at, 
                       f.image, f.found_at, f.status, f.created_at,
                       c.name as category
                FROM found_item f
                LEFT JOIN item_category c ON f.item_category_id = c.id
                ORDER BY f.created_at DESC
                LIMIT %s
            """, (limit,))
            items = cursor.fetchall()

        return {
            "status": "success",
            "count": len(items),
            "data": items
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"최근 아이템 조회 실패: {str(e)}")
    finally:
        conn.close()

@router.get("/stats/time")
async def get_time_stats(
    period: str = Query("day", description="집계 기간 (day, week, month)"),
    days: int = Query(7, ge=1, le=30, description="조회할 일 수")
):
    """
    시간대별 수집 통계 제공
    """
    conn = get_db_connection()
    try:
        stats = []
        end_date = datetime.utcnow().date()
        start_date = end_date - timedelta(days=days-1)

        if period == "day":
            # 일별 통계
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT DATE(created_at) as date, COUNT(*) as count
                    FROM found_item
                    WHERE DATE(created_at) BETWEEN %s AND %s
                    GROUP BY DATE(created_at)
                    ORDER BY date
                """, (start_date, end_date))
                stats = cursor.fetchall()
        elif period == "week":
            # 주별 통계
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT YEARWEEK(created_at) as week, COUNT(*) as count
                    FROM found_item
                    WHERE DATE(created_at) BETWEEN %s AND %s
                    GROUP BY YEARWEEK(created_at)
                    ORDER BY week
                """, (start_date - timedelta(days=7*4), end_date))
                stats = cursor.fetchall()
        elif period == "month":
            # 월별 통계
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT DATE_FORMAT(created_at, '%Y-%m') as month, COUNT(*) as count
                    FROM found_item
                    WHERE DATE(created_at) >= DATE_SUB(%s, INTERVAL 12 MONTH)
                    GROUP BY DATE_FORMAT(created_at, '%Y-%m')
                    ORDER BY month
                """, (end_date,))
                stats = cursor.fetchall()

        return {
            "status": "success",
            "period": period,
            "data": stats
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"시간대별 통계 조회 실패: {str(e)}")
    finally:
        conn.close()

@router.get("/locations")
async def get_location_stats(limit: int = Query(100, ge=1, le=1000)):
    """
    위치별 수집 통계 제공 (지도 시각화용)
    """
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute("""
                SELECT stored_at as location, 
                       ST_X(coordinates) as longitude, 
                       ST_Y(coordinates) as latitude,
                       COUNT(*) as count
                FROM found_item
                WHERE coordinates IS NOT NULL
                GROUP BY stored_at, coordinates
                ORDER BY count DESC
                LIMIT %s
            """, (limit,))
            locations = cursor.fetchall()

        return {
            "status": "success",
            "count": len(locations),
            "data": locations
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"위치 통계 조회 실패: {str(e)}")
    finally:
        conn.close()

@router.get("/clean-hdfs", response_model=Dict[str, Any])
async def clean_hdfs_images(
    dry_run: bool = Query(True, description="테스트 모드 (true일 경우 실제 삭제하지 않음)"),
    limit: int = Query(100, description="한 번에 처리할 최대 이미지 수", ge=1, le=1000)
):
    """
    HDFS에서 사용되지 않는 이미지(Elasticsearch에 참조되지 않는 이미지)를 찾아 정리합니다.
    """
    try:
        from elasticsearch import Elasticsearch
        from hdfs import InsecureClient
        import re
        import os
        from config.config import ES_HOST, ES_PORT, ES_INDEX, HDFS_URL

        # Elasticsearch 클라이언트 생성
        es = Elasticsearch([{'host': ES_HOST, 'port': ES_PORT, 'scheme': 'http'}])
        
        # HDFS 클라이언트 생성
        hdfs_client = InsecureClient(HDFS_URL, user='ubuntu')
        
        # HDFS URL에서 경로 추출 함수
        def extract_hdfs_path(hdfs_url):
            if not hdfs_url:
                return None
            match = re.search(r'hdfs://[^/]+(/.*)', hdfs_url)
            if match:
                return match.group(1)
            return None
        
        # Elasticsearch에서 모든 HDFS 경로 가져오기
        es_paths = set()
        query = {
            "query": {
                "exists": {
                    "field": "image_hdfs"
                }
            },
            "_source": ["image_hdfs"],
            "size": 1000
        }
        
        response = es.search(index=ES_INDEX, body=query, scroll="1m")
        scroll_id = response['_scroll_id']
        
        # 첫 번째 배치 처리
        for hit in response['hits']['hits']:
            hdfs_url = hit['_source'].get('image_hdfs')
            if hdfs_url:
                path = extract_hdfs_path(hdfs_url)
                if path:
                    es_paths.add(path)
        
        # 스크롤 API로 나머지 문서 처리
        while True:
            response = es.scroll(scroll_id=scroll_id, scroll="1m")
            hits = response['hits']['hits']
            if not hits:
                break
                
            for hit in hits:
                hdfs_url = hit['_source'].get('image_hdfs')
                if hdfs_url:
                    path = extract_hdfs_path(hdfs_url)
                    if path:
                        es_paths.add(path)
            
            scroll_id = response['_scroll_id']
        
        # HDFS에서 모든 이미지 경로 가져오기
        base_dir = "/found_items/images"
        hdfs_paths = set()
        
        if hdfs_client.status(base_dir, strict=False) is not None:
            for root, _, file_list in hdfs_client.walk(base_dir):
                for file in file_list:
                    hdfs_paths.add(os.path.join(root, file))
        
        # 사용되지 않는 이미지 찾기
        unused_images = list(hdfs_paths - es_paths)
        total_unused = len(unused_images)
        
        # 한 번에 처리할 이미지 수 제한
        unused_images = unused_images[:limit]
        
        # 삭제 처리
        result = {
            "total_es_images": len(es_paths),
            "total_hdfs_images": len(hdfs_paths),
            "total_unused_images": total_unused,
            "processing_limit": limit,
            "images_to_process": len(unused_images),
            "dry_run": dry_run,
            "deleted": [],
            "errors": []
        }
        
        if not dry_run:
            for path in unused_images:
                try:
                    hdfs_client.delete(path)
                    result["deleted"].append(path)
                except Exception as e:
                    result["errors"].append({"path": path, "error": str(e)})
        else:
            # 테스트 모드에서는 삭제할 이미지 목록만 제공
            result["images_to_delete"] = unused_images
        
        return result
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        raise HTTPException(status_code=500, detail=f"HDFS 이미지 정리 중 오류: {str(e)}\n{error_details}")
    
@router.post("/clean-hdfs-csv", response_model=Dict[str, Any])
async def clean_hdfs_csv_file(
    file_path: str = Query("/found_items/processed/found_item.csv", description="정리할 HDFS CSV 파일 경로"),
    id_column: str = Query("management_id", description="식별자로 사용할 CSV 컬럼명"),
    dry_run: bool = Query(True, description="테스트 모드 (true일 경우 실제 변경하지 않음)")
):
    """
    HDFS CSV 파일에서 Elasticsearch에 없는 레코드를 제거합니다.
    """
    try:
        from elasticsearch import Elasticsearch
        from hdfs import InsecureClient
        import pandas as pd
        import io
        import csv
        import re
        from config.config import ES_HOST, ES_PORT, ES_INDEX, HDFS_URL
        
        # Elasticsearch 클라이언트 생성
        es = Elasticsearch([{'host': ES_HOST, 'port': ES_PORT, 'scheme': 'http'}])
        
        # HDFS 클라이언트 생성
        hdfs_client = InsecureClient(HDFS_URL, user='ubuntu')
        
        # 파일 존재 여부 확인
        file_exists = hdfs_client.status(file_path, strict=False) is not None
        
        result = {
            "file_path": file_path,
            "file_exists": file_exists,
            "dry_run": dry_run,
            "total_records": 0,
            "records_in_elasticsearch": 0,
            "records_to_remove": 0,
            "success": False,
            "message": ""
        }
        
        if not file_exists:
            result["message"] = f"파일이 존재하지 않습니다: {file_path}"
            return result
        
        # CSV 파일 읽기
        with hdfs_client.read(file_path) as reader:
            content = reader.read()
            csv_text = content.decode('utf-8')
            
            # DataFrame으로 변환 (오류 처리 매개변수 추가)
            try:
                # 첫 번째 방법: Python 엔진으로 시도
                df = pd.read_csv(
                    io.StringIO(csv_text),
                    engine='python',
                    on_bad_lines='skip',
                    quotechar='"',
                    escapechar='\\',
                )
            except Exception as e1:
                try:
                    # 두 번째 방법: CSV를 수동으로 파싱
                    # 헤더 줄 가져오기
                    header_line = csv_text.split('\n', 1)[0]
                    headers = header_line.split(',')
                    
                    # 각 레코드를 추출하여 데이터프레임 구성
                    pattern = r'(F\d{13}),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),(.*?),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),(\d+),({.*?})'
                    matches = re.findall(pattern, csv_text, re.DOTALL)
                    
                    records = []
                    for match in matches:
                        record = {
                            'management_id': match[0],
                            'color': match[1],
                            'stored_at': match[2],
                            'image': match[3],
                            'name': match[4],
                            'found_at': match[5],
                            'status': match[6],
                            'location': match[7],
                            'phone': match[8],
                            'detail': match[9],
                            'image_hdfs': match[10],
                            'latitude': match[11],
                            'longitude': match[12],
                            'category_major': match[13],
                            'category_minor': match[14],
                            'mysql_id': match[15],
                            'location_geo': match[16]
                        }
                        records.append(record)
                    
                    df = pd.DataFrame(records)
                    
                except Exception as e2:
                    # 세 번째 방법: 헤더만 추출하고 management_id만 포함된 DataFrame 생성
                    header_line = csv_text.split('\n', 1)[0]
                    headers = header_line.split(',')
                    
                    # management_id 추출
                    id_pattern = r'(F\d{13})'
                    ids = re.findall(id_pattern, csv_text)
                    
                    df = pd.DataFrame({id_column: ids})
                    result["message"] += f"완전한 CSV 파싱 실패. ID만 추출하여 진행합니다. 오류1: {str(e1)}, 오류2: {str(e2)}"
            
        # ID 컬럼 확인
        if id_column not in df.columns:
            result["message"] = f"CSV 파일에 '{id_column}' 컬럼이 없습니다. 사용 가능한 컬럼: {', '.join(df.columns.tolist())}"
            return result
            
        # 총 레코드 수
        total_records = len(df)
        result["total_records"] = total_records
        
        # Elasticsearch에 있는 ID 목록 가져오기
        ids_in_es = set()
        ids_to_check = df[id_column].dropna().unique().tolist()
        
        # 작은 배치로 나누어 검색
        batch_size = 1000
        for i in range(0, len(ids_to_check), batch_size):
            batch_ids = ids_to_check[i:i+batch_size]
            query = {
                "query": {
                    "terms": {
                        f"{id_column}.keyword": batch_ids
                    }
                },
                "_source": [id_column],
                "size": batch_size
            }
            
            response = es.search(index=ES_INDEX, body=query)
            for hit in response['hits']['hits']:
                if id_column in hit['_source']:
                    ids_in_es.add(hit['_source'][id_column])
        
        # Elasticsearch에 없는 레코드 필터링
        df_to_keep = df[df[id_column].isin(ids_in_es)]
        records_to_remove = total_records - len(df_to_keep)
        
        result["records_in_elasticsearch"] = len(df_to_keep)
        result["records_to_remove"] = records_to_remove
        
        if not dry_run and records_to_remove > 0:
            # CSV 파일 업데이트
            csv_output = df_to_keep.to_csv(index=False, quoting=csv.QUOTE_ALL)
            
            # HDFS에 쓰기 - UTF-8 인코딩 적용
            hdfs_client.write(file_path, data=csv_output, overwrite=True, encoding='utf-8')
            
            result["success"] = True
            result["message"] += f"{records_to_remove}개 레코드가 제거되었습니다."
        else:
            result["message"] += f"테스트 모드: {records_to_remove}개 레코드가 제거될 예정입니다. 실제 적용하려면 dry_run=false로 설정하세요."
            result["success"] = True
            
        return result
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        raise HTTPException(status_code=500, detail=f"HDFS CSV 파일 정리 중 오류: {str(e)}\n{error_details}")
    
@router.get("/hdfs-csv-preview", response_model=Dict[str, Any])
async def preview_hdfs_csv_file(
    file_path: str = Query("/found_items/processed/found_item.csv", description="미리 볼 HDFS CSV 파일 경로"),
    lines: int = Query(10, description="미리 볼 줄 수", ge=1, le=1000),
    start_line: int = Query(0, description="시작 줄 번호", ge=0)
):
    """
    HDFS CSV 파일의 내용을 미리 봅니다.
    """
    try:
        from hdfs import InsecureClient
        from config.config import HDFS_URL
        
        # HDFS 클라이언트 생성
        hdfs_client = InsecureClient(HDFS_URL, user='ubuntu')
        
        # 파일 존재 여부 확인
        file_exists = hdfs_client.status(file_path, strict=False) is not None
        
        if not file_exists:
            return {
                "file_path": file_path,
                "file_exists": False,
                "message": "파일이 존재하지 않습니다."
            }
        
        # 파일 읽기
        with hdfs_client.read(file_path) as reader:
            content = reader.read()
            text_content = content.decode('utf-8')
            
            # 줄 단위로 분할
            all_lines = text_content.splitlines()
            total_lines = len(all_lines)
            
            # 요청된 범위의 줄 추출
            end_line = min(start_line + lines, total_lines)
            selected_lines = all_lines[start_line:end_line]
            
            # 문제가 있는 줄 근처 확인 (125번째 줄)
            problem_area = []
            problem_line = 125  # 오류 메시지에서 가져온 줄 번호
            if problem_line < total_lines:
                start_problem = max(0, problem_line - 2)
                end_problem = min(total_lines, problem_line + 3)
                problem_area = all_lines[start_problem:end_problem]
                
            return {
                "file_path": file_path,
                "file_exists": True,
                "total_lines": total_lines,
                "start_line": start_line,
                "end_line": end_line - 1,
                "lines": selected_lines,
                "problem_line_number": problem_line,
                "problem_area": problem_area
            }
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        raise HTTPException(status_code=500, detail=f"HDFS CSV 파일 미리보기 중 오류: {str(e)}\n{error_details}")
    
@router.post("/restore-hdfs-csv-fixed", response_model=Dict[str, Any])
async def restore_hdfs_csv_fixed(
    file_path: str = Query("/found_items/processed/found_item.csv", description="생성할 HDFS CSV 파일 경로"),
    batch_size: int = Query(1000, description="한 번에 처리할 Elasticsearch 문서 수", ge=100, le=5000),
    overwrite: bool = Query(True, description="기존 파일 덮어쓰기 여부")
):
    """
    Elasticsearch에서 데이터를 가져와 올바른 CSV 형식으로 HDFS에 저장합니다.
    줄바꿈과 따옴표 처리 문제를 해결한 버전입니다.
    """
    try:
        from elasticsearch import Elasticsearch
        from hdfs import InsecureClient
        import csv
        import io
        import json
        import time
        from config.config import ES_HOST, ES_PORT, ES_INDEX, HDFS_URL
        
        # Elasticsearch 클라이언트 생성
        es = Elasticsearch([{'host': ES_HOST, 'port': ES_PORT, 'scheme': 'http'}])
        
        # HDFS 클라이언트 생성
        hdfs_client = InsecureClient(HDFS_URL, user='ubuntu')
        
        # 결과 초기화
        result = {
            "file_path": file_path,
            "es_index": ES_INDEX,
            "total_documents": 0,
            "processed_documents": 0,
            "csv_file_created": False,
            "success": False,
            "message": "",
            "error": None,
            "start_time": time.time(),
            "elapsed_time_seconds": 0
        }
        
        # 기존 파일 존재 여부 확인
        file_exists = hdfs_client.status(file_path, strict=False) is not None
        
        if file_exists and not overwrite:
            result["message"] = f"파일이 이미 존재합니다: {file_path}. 덮어쓰려면 overwrite=true를 사용하세요."
            return result
        
        # Elasticsearch에서 총 문서 수 확인
        count_resp = es.count(index=ES_INDEX)
        total_docs = count_resp["count"]
        result["total_documents"] = total_docs
        
        if total_docs == 0:
            result["message"] = f"Elasticsearch 인덱스 {ES_INDEX}에 문서가 없습니다."
            return result
        
        # 데이터 디렉토리 확인 및 생성
        directory = "/".join(file_path.split("/")[:-1])
        try:
            if not hdfs_client.status(directory, strict=False):
                hdfs_client.makedirs(directory)
                result["message"] += f"디렉토리 생성됨: {directory}. "
        except Exception as e:
            hdfs_client.makedirs(directory)
            result["message"] += f"디렉토리 생성 중 예외 처리됨: {directory}. "
        
        # 키 필드 및 순서 정의
        key_fields = [
            "management_id", "color", "stored_at", "image", "name", "found_at", 
            "status", "location", "phone", "detail", "image_hdfs", "latitude", 
            "longitude", "category_major", "category_minor", "mysql_id", "location_geo"
        ]
        
        # CSV 문자열 생성 함수
        def escape_csv_field(field):
            if field is None:
                return ""
            
            # 딕셔너리나 리스트는 JSON 문자열로 변환
            if isinstance(field, (dict, list)):
                field = json.dumps(field, ensure_ascii=False)
            
            # 문자열로 변환
            field = str(field)
            
            # 줄바꿈 문자를 공백으로 대체
            field = field.replace("\n", " ").replace("\r", " ")
            
            # CSV 이스케이프 규칙에 따라 처리
            if '"' in field:
                field = field.replace('"', '""')
            
            # 필드 전체를 따옴표로 감싸기
            return f'"{field}"'
        
        # 스크롤 API를 사용하여 모든 문서 가져오기
        processed_docs = 0
        scroll_size = batch_size
        scroll_id = None
        first_batch = True
        
        # 덮어쓰기 모드인 경우 기존 파일 삭제
        if file_exists and overwrite:
            hdfs_client.delete(file_path)
            result["message"] += f"기존 파일 삭제됨: {file_path}. "
        
        while processed_docs < total_docs:
            if scroll_id is None:
                # 첫 번째 배치
                query = {
                    "query": {
                        "match_all": {}
                    },
                    "size": batch_size,
                    "sort": [
                        {"_id": "asc"}
                    ]
                }
                resp = es.search(index=ES_INDEX, body=query, scroll="2m")
                scroll_id = resp["_scroll_id"]
            else:
                # 이후 배치
                resp = es.scroll(scroll_id=scroll_id, scroll="2m")
            
            # 스크롤 사이즈 업데이트
            scroll_size = len(resp["hits"]["hits"])
            if scroll_size == 0:
                break  # 더 이상 문서가 없음
                
            # 배치 처리
            docs = [hit["_source"] for hit in resp["hits"]["hits"]]
            
            # CSV 행을 수동으로 생성
            csv_rows = []
            
            # 첫 배치에는 헤더 추가
            if first_batch:
                header_row = ",".join([f'"{field}"' for field in key_fields])
                csv_rows.append(header_row)
                first_batch = False
            
            # 각 문서를 CSV 행으로 변환
            for doc in docs:
                row_values = []
                for field in key_fields:
                    # 필드가 없으면 빈 값 추가
                    value = doc.get(field, "")
                    row_values.append(escape_csv_field(value))
                
                csv_rows.append(",".join(row_values))
            
            # CSV 내용 생성 및 HDFS에 쓰기
            csv_content = "\n".join(csv_rows)
            
            # HDFS에 쓰기
            if processed_docs == 0:
                # 첫 배치
                hdfs_client.write(file_path, data=csv_content.encode('utf-8'), overwrite=True)
            else:
                # 이후 배치 (새 줄 문자 추가)
                hdfs_client.write(file_path, data=f"\n{csv_content}".encode('utf-8'), append=True)
            
            processed_docs += scroll_size
            result["processed_documents"] = processed_docs
            
            # 진행 상황 로그
            progress = (processed_docs / total_docs) * 100
            logger.info(f"CSV 생성 진행 중: {processed_docs}/{total_docs} 문서 처리됨 ({progress:.1f}%)")
        
        # 결과 업데이트
        result["csv_file_created"] = True
        result["success"] = True
        result["elapsed_time_seconds"] = time.time() - result["start_time"]
        result["message"] += f"Elasticsearch에서 {processed_docs}개 문서를 가져와 HDFS에 CSV 파일 생성 완료."
        
        return result
            
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        logger.error(f"HDFS CSV 복원 중 오류: {str(e)}\n{error_details}")
        
        # 결과 업데이트
        if "result" in locals():
            result["error"] = str(e)
            result["elapsed_time_seconds"] = time.time() - result["start_time"]
            return result
        else:
            return {
                "success": False,
                "message": "HDFS CSV 복원 중 오류 발생",
                "error": str(e)
            }

@router.post("/sync-missing-data", response_model=Dict[str, Any])
async def sync_missing_data(
    batch_size: int = Query(100, description="한 번에 처리할 최대 레코드 수", ge=10, le=500),
    dry_run: bool = Query(True, description="테스트 모드 (true일 경우 실제 저장하지 않음)")
):
    """
    MySQL에서 Elasticsearch에 없는 데이터를 찾아 이미지 처리 후 Elasticsearch와 HDFS에 저장합니다.
    """
    try:
        import pymysql
        from pymysql.cursors import DictCursor
        from elasticsearch import Elasticsearch
        import time
        import json
        import concurrent.futures
        import cv2
        import numpy as np
        import requests
        import uuid
        import threading
        from hdfs import InsecureClient
        from config.config import (
            DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME,
            ES_HOST, ES_PORT, ES_INDEX, HDFS_URL, HDFS_NAMENODE, HDFS_PORT,
            S3_BUCKET, AWS_ACCESS_KEY, AWS_SECRET_KEY, AWS_REGION,
            IMAGE_RESIZE_WIDTH, IMAGE_RESIZE_HEIGHT
        )
        
        # 결과 초기화
        result = {
            "start_time": time.time(),
            "total_mysql_records": 0,
            "total_elasticsearch_records": 0,
            "missing_records_count": 0,
            "processed_records_count": 0,
            "successfully_processed": 0,
            "errors": [],
            "processed_details": [],
            "dry_run": dry_run,
            "success": False,
            "elapsed_time_seconds": 0,
            "message": ""
        }
        
        # 데이터베이스 연결
        db_conn = pymysql.connect(
            host=DB_HOST,
            port=DB_PORT,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME,
            charset='utf8mb4',
            cursorclass=DictCursor
        )
        
        # Elasticsearch 클라이언트 생성
        es = Elasticsearch([{'host': ES_HOST, 'port': ES_PORT, 'scheme': 'http'}])
        
        # HDFS 클라이언트 생성
        hdfs_client = InsecureClient(HDFS_URL, user="root")
        
        # CSV 쓰기 작업을 위한 락 생성
        hdfs_write_lock = threading.Lock()
        
        # 데이터베이스에서 총 레코드 수 확인
        with db_conn.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) as count FROM found_item")
            mysql_count = cursor.fetchone()["count"]
            result["total_mysql_records"] = mysql_count
        
        # Elasticsearch에서 총 레코드 수 확인
        es_count = es.count(index=ES_INDEX)["count"]
        result["total_elasticsearch_records"] = es_count
        
        # Elasticsearch에서 모든 mysql_id 가져오기
        es_ids = set()
        query = {
            "query": {"match_all": {}},
            "_source": ["mysql_id"],
            "size": 10000
        }
        
        # 스크롤 API 사용
        response = es.search(index=ES_INDEX, body=query, scroll="2m")
        scroll_id = response["_scroll_id"]
        
        # 첫 페이지 처리
        for hit in response["hits"]["hits"]:
            if "mysql_id" in hit["_source"]:
                es_ids.add(str(hit["_source"]["mysql_id"]))
        
        # 나머지 페이지 처리
        while True:
            response = es.scroll(scroll_id=scroll_id, scroll="2m")
            hits = response["hits"]["hits"]
            if not hits:
                break
                
            for hit in hits:
                if "mysql_id" in hit["_source"]:
                    es_ids.add(str(hit["_source"]["mysql_id"]))
            
            scroll_id = response["_scroll_id"]
        
        logger.info(f"MySQL 레코드 수: {mysql_count}, Elasticsearch 레코드 수: {es_count}, Elasticsearch의 MySQL ID 수: {len(es_ids)}")
        
        # MySQL에서 Elasticsearch에 없는 레코드 가져오기 (MINOR 카테고리)
        all_records = []
        with db_conn.cursor() as cursor:
            # MINOR 카테고리 정보를 포함하여 조회
            cursor.execute("""
                SELECT f.*, 
                       child_cat.name as category_minor,
                       parent_cat.name as category_major
                FROM found_item f
                LEFT JOIN item_category child_cat ON f.item_category_id = child_cat.id
                LEFT JOIN item_category parent_cat ON child_cat.parent_id = parent_cat.id AND parent_cat.level = 'MAJOR'
                WHERE child_cat.level = 'MINOR'
                ORDER BY f.id DESC
            """)
            all_records = cursor.fetchall()
        
        # MAJOR 카테고리만 있는 레코드 조회
        with db_conn.cursor() as cursor:
            cursor.execute("""
                SELECT f.*, 
                       cat.name as category_major,
                       NULL as category_minor
                FROM found_item f
                INNER JOIN item_category cat ON f.item_category_id = cat.id
                WHERE cat.level = 'MAJOR'
                ORDER BY f.id DESC
            """)
            major_records = cursor.fetchall()
            all_records.extend(major_records)
        
        # 카테고리 정보 없는 레코드도 조회
        with db_conn.cursor() as cursor:
            cursor.execute("""
                SELECT f.*, 
                       NULL as category_major,
                       NULL as category_minor
                FROM found_item f
                LEFT JOIN item_category cat ON f.item_category_id = cat.id
                WHERE cat.id IS NULL
                ORDER BY f.id DESC
            """)
            no_category_records = cursor.fetchall()
            all_records.extend(no_category_records)
        
        # Elasticsearch에 없는 레코드 필터링
        missing_records = [record for record in all_records if str(record["id"]) not in es_ids]
        result["missing_records_count"] = len(missing_records)
        
        logger.info(f"Elasticsearch에 없는 MySQL 레코드 수: {len(missing_records)}")
        
        # 처리할 최대 레코드 수 제한
        records_to_process = missing_records[:batch_size]
        result["processed_records_count"] = len(records_to_process)
        
        # HDFS CSV 파일을 위한 경로 정의
        hdfs_csv_path = "/found_items/processed/found_item.csv"
        
        # CSV 헤더 정의
        csv_headers = [
            "management_id", "color", "stored_at", "image", "name", "found_at", 
            "status", "location", "phone", "detail", "image_hdfs", "latitude", 
            "longitude", "category_major", "category_minor", "mysql_id", "location_geo"
        ]
        
        # 테스트 모드에서는 실제 처리하지 않음
        if dry_run:
            # 테스트 모드에서도 카테고리 정보 제공
            category_info = []
            for record in records_to_process[:10]:  # 처음 10개만 샘플로 제공
                category_info.append({
                    "id": record["id"],
                    "management_id": record["management_id"],
                    "item_category_id": record["item_category_id"],
                    "category_major": record.get("category_major") or "",
                    "category_minor": record.get("category_minor") or "",
                    "name": record["name"]
                })
            
            result["category_samples"] = category_info
            result["message"] = f"테스트 모드: {len(records_to_process)}개 레코드를 처리할 예정입니다. 실제 처리하려면 dry_run=false로 설정하세요."
            result["success"] = True
            result["elapsed_time_seconds"] = time.time() - result["start_time"]
            db_conn.close()
            return result
        
        # 이미지 처리 함수
        def process_image(image_url):
            """이미지 다운로드, 처리 및 업로드 함수"""
            if not image_url or not isinstance(image_url, str) or not image_url.startswith("http"):
                return {"s3_url": None, "hdfs_url": None}
            
            # 기본 이미지인 경우 처리하지 않음
            if "img02_no_img.gif" in image_url:
                logger.info(f"기본 이미지 감지됨: {image_url} → 전처리 건너뜀")
                return {"s3_url": None, "hdfs_url": None}
            
            try:
                # 1. 이미지 다운로드
                logger.debug(f"이미지 다운로드 시작: {image_url}")
                response = requests.get(image_url, stream=True, timeout=10)
                response.raise_for_status()
                image_data = np.asarray(bytearray(response.content), dtype=np.uint8)
                img = cv2.imdecode(image_data, cv2.IMREAD_COLOR)
                if img is None:
                    raise ValueError("이미지 디코딩 실패")
                logger.debug(f"이미지 다운로드 완료: {image_url}")
                
                # 2. 이미지 전처리
                # LAB 색 공간 변환 및 CLAHE 적용 (명암 조정)
                lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
                l_channel, a_channel, b_channel = cv2.split(lab)
                clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
                l_channel_eq = clahe.apply(l_channel)
                lab_eq = cv2.merge((l_channel_eq, a_channel, b_channel))
                enhanced = cv2.cvtColor(lab_eq, cv2.COLOR_LAB2BGR)
                
                # 언샤프 마스킹을 통한 선명도 개선
                gaussian = cv2.GaussianBlur(enhanced, (0, 0), sigmaX=3)
                sharpened = cv2.addWeighted(enhanced, 1.5, gaussian, -0.5, 0)
                
                # 밝기 조절 (어둡게)
                processed = cv2.convertScaleAbs(sharpened, alpha=1.0, beta=-20)
                
                # 리사이징
                processed_resized = cv2.resize(processed, (IMAGE_RESIZE_WIDTH, IMAGE_RESIZE_HEIGHT))
                
                # 3. 이미지 인코딩
                success, buffer = cv2.imencode('.jpg', processed_resized, [cv2.IMWRITE_JPEG_QUALITY, 90])
                if not success:
                    raise ValueError("이미지 인코딩 실패")
                image_bytes = buffer.tobytes()
                
                # 4. HDFS에 업로드
                hdfs_filename = f"{uuid.uuid4().hex}.jpg"
                hdfs_path = f"/found_items/images/{hdfs_filename}"
                
                try:
                    # HDFS 디렉토리 확인 및 생성
                    hdfs_dir = "/found_items/images"
                    if not hdfs_client.status(hdfs_dir, strict=False):
                        hdfs_client.makedirs(hdfs_dir)
                    
                    # 이미지 업로드
                    hdfs_client.write(hdfs_path, data=image_bytes, overwrite=True)
                    hdfs_url = f"hdfs://{HDFS_NAMENODE}:{HDFS_PORT}{hdfs_path}"
                    logger.info(f"이미지 HDFS 저장 성공: {hdfs_url}")
                except Exception as hdfs_err:
                    logger.error(f"HDFS 업로드 에러: {hdfs_err}")
                    hdfs_url = None
                
                # S3 업로드는 선택적으로 수행
                s3_url = image_url  # 기본값으로 원래 URL 유지
                
                return {"s3_url": s3_url, "hdfs_url": hdfs_url}
            except Exception as e:
                logger.error(f"이미지 처리 및 업로드 에러 ({image_url}): {e}")
                return {"s3_url": image_url, "hdfs_url": None}
        
        # 사전에 HDFS CSV 파일 준비
        # 파일 존재 여부 확인
        csv_file_exists = False
        try:
            csv_file_exists = hdfs_client.status(hdfs_csv_path, strict=False) is not None
        except:
            pass
        
        # 파일이 없으면 헤더와 함께 생성
        if not csv_file_exists:
            header_row = ",".join([f'"{h}"' for h in csv_headers]) + "\n"
            hdfs_client.write(hdfs_csv_path, data=header_row.encode('utf-8'), overwrite=True)
            logger.info(f"HDFS CSV 파일 초기화 완료: {hdfs_csv_path}")
        
        # CSV 행 데이터를 모을 리스트 - 한 번에 업데이트하기 위함
        csv_rows = []
        
        # CSV 필드 이스케이프 함수
        def escape_csv_field(field):
            if field is None:
                return ""
            
            # 딕셔너리나 리스트는 JSON 문자열로 변환
            if isinstance(field, (dict, list)):
                field = json.dumps(field, ensure_ascii=False)
            
            # 문자열로 변환
            field = str(field)
            
            # 줄바꿈 문자를 공백으로 대체
            field = field.replace("\n", " ").replace("\r", " ")
            
            # CSV 이스케이프 규칙에 따라 처리
            if '"' in field:
                field = field.replace('"', '""')
            
            # 필드 전체를 따옴표로 감싸기
            return f'"{field}"'
        
        # 실제 처리 로직
        successfully_processed = []
        errors = []
        processed_details = []
        
        # 카테고리 정보 확인용 데이터 수집
        category_mapping = {}
        
        # 레코드 처리 함수
        def process_record(record):
            try:
                record_id = record["id"]
                management_id = record["management_id"]
                
                # 카테고리 정보 기록
                category_info = {
                    "item_category_id": record["item_category_id"],
                    "category_major": record.get("category_major") or "",
                    "category_minor": record.get("category_minor") or ""
                }
                category_mapping[record_id] = category_info
                
                # 이미지 처리
                image_url = record["image"]
                image_urls = process_image(image_url)
                
                # 위치 정보 처리
                latitude = 0.0
                longitude = 0.0
                if "coordinates" in record and record["coordinates"]:
                    # ST_X, ST_Y 함수 결과 처리
                    try:
                        if "ST_X(coordinates)" in record and record["ST_X(coordinates)"]:
                            longitude = float(record["ST_X(coordinates)"])
                        if "ST_Y(coordinates)" in record and record["ST_Y(coordinates)"]:
                            latitude = float(record["ST_Y(coordinates)"])
                    except (TypeError, ValueError):
                        pass
                else:
                    # 단순 latitude, longitude 필드 사용
                    try:
                        if "latitude" in record and record["latitude"]:
                            latitude = float(record["latitude"])
                        if "longitude" in record and record["longitude"]:
                            longitude = float(record["longitude"])
                    except (TypeError, ValueError):
                        pass
                
                # 중첩된 좌표 객체 추가
                location_geo = {"lat": latitude, "lon": longitude}
                
                # Elasticsearch 문서 생성
                es_doc = {
                    "management_id": management_id,
                    "color": record.get("color", ""),
                    "stored_at": record.get("stored_at", ""),
                    "image": record.get("image", ""),
                    "name": record.get("name", ""),
                    "found_at": record.get("found_at").isoformat() if record.get("found_at") else None,
                    "status": record.get("status", "STORED"),
                    "location": record.get("location", ""),
                    "phone": record.get("phone", ""),
                    "detail": record.get("detail", ""),
                    "image_hdfs": image_urls.get("hdfs_url"),
                    "latitude": latitude,
                    "longitude": longitude,
                    "category_major": record.get("category_major") or "",
                    "category_minor": record.get("category_minor") or "",
                    "mysql_id": str(record_id),
                    "location_geo": location_geo,
                    "created_at": record.get("created_at").isoformat() if record.get("created_at") else None
                }
                
                # Elasticsearch에 저장
                es.index(index=ES_INDEX, id=str(record_id), document=es_doc)
                
                # CSV 행 생성
                row_values = []
                for key in csv_headers:
                    value = es_doc.get(key, "")
                    row_values.append(escape_csv_field(value))
                
                csv_row = ",".join(row_values) + "\n"
                
                # CSV 행 정보 저장 (나중에 일괄 처리를 위해)
                with hdfs_write_lock:
                    csv_rows.append(csv_row)
                
                # 처리 세부 정보 기록
                process_detail = {
                    "id": record_id,
                    "management_id": management_id,
                    "name": record.get("name", ""),
                    "category_major": record.get("category_major") or "",
                    "category_minor": record.get("category_minor") or "",
                    "image_hdfs": image_urls.get("hdfs_url"),
                    "status": "success"
                }
                
                return process_detail
            except Exception as e:
                import traceback
                error_details = traceback.format_exc()
                logger.error(f"레코드 처리 오류 (ID: {record.get('id')}): {e}\n{error_details}")
                return {
                    "id": record.get('id'),
                    "management_id": record.get('management_id'),
                    "name": record.get('name', ''),
                    "status": "error",
                    "error": str(e)
                }
        
        # 멀티스레드로 레코드 처리
        with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
            futures = [executor.submit(process_record, record) for record in records_to_process]
            
            for future in concurrent.futures.as_completed(futures):
                result_item = future.result()
                if result_item["status"] == "success":
                    successfully_processed.append(result_item)
                    processed_details.append(result_item)
                else:
                    errors.append(result_item)
                    processed_details.append(result_item)
        
        # 모든 스레드 처리가 완료된 후 CSV 파일에 일괄 저장
        if csv_rows:
            try:
                # CSV 데이터 일괄 저장
                all_csv_data = "".join(csv_rows)
                hdfs_client.write(hdfs_csv_path, data=all_csv_data.encode('utf-8'), append=True)
                logger.info(f"CSV 데이터 {len(csv_rows)}개 행 일괄 저장 완료")
            except Exception as csv_err:
                logger.error(f"CSV 데이터 일괄 저장 중 오류: {csv_err}")
                # 실패 시 개별 파일에 저장
                try:
                    backup_path = f"/found_items/processed/found_item_backup_{int(time.time())}.csv"
                    hdfs_client.write(backup_path, data=all_csv_data.encode('utf-8'), overwrite=True)
                    logger.info(f"백업 CSV 파일 생성: {backup_path}")
                except Exception as backup_err:
                    logger.error(f"백업 CSV 생성 중 오류: {backup_err}")
        
        # 결과 업데이트
        result["successfully_processed"] = len(successfully_processed)
        result["errors"] = errors
        result["processed_details"] = processed_details
        result["success"] = True
        result["elapsed_time_seconds"] = time.time() - result["start_time"]
        result["message"] = f"{len(successfully_processed)}개 레코드가 성공적으로 처리되었습니다. {len(errors)}개 오류 발생."
        
        # 데이터베이스 연결 종료
        db_conn.close()
        
        return result
            
    except Exception as e:
        import traceback
        error_details = traceback.format_exc()
        logger.error(f"데이터 동기화 중 오류: {str(e)}\n{error_details}")
        
        if "result" in locals():
            result["error"] = str(e)
            result["elapsed_time_seconds"] = time.time() - result["start_time"]
            result["success"] = False
            return result
        else:
            return {
                "success": False,
                "message": "데이터 동기화 중 오류 발생",
                "error": str(e)
            }