"""
데이터 정합성 관리 및 클린업 관련 API 라우트
MySQL과 다른 데이터 스토어(Elasticsearch, HDFS) 간의 정합성을 유지하기 위한 엔드포인트를 제공합니다.
"""
import os
from fastapi import APIRouter, HTTPException, BackgroundTasks, Query
from typing import Any
from datetime import datetime
import pymysql
from pymysql.cursors import DictCursor
import logging
import threading
from elasticsearch import Elasticsearch, helpers
from hdfs import InsecureClient

from config.config import (
    DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME,
    ES_HOST, ES_PORT, ES_INDEX,
    HDFS_URL, ES_USERNAME, ES_PASSWORD
)

logger = logging.getLogger(__name__)
router = APIRouter(
    prefix="/cleanup",
    tags=["데이터 정합성 관리"],
    responses={404: {"description": "Not found"}},
)

def get_db_connection():
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

def get_es_client():
    try:
        es = Elasticsearch(
            hosts=[{'host': ES_HOST, 'port': ES_PORT, 'scheme': 'http'}],
            timeout=30,
            http_auth=(ES_USERNAME, ES_PASSWORD) if ES_USERNAME and ES_PASSWORD else None
        )
        return es
    except Exception as e:
        logger.error(f"Elasticsearch 연결 실패: {e}")
        raise HTTPException(status_code=500, detail=f"Elasticsearch 연결 실패: {str(e)}")

def get_hdfs_client():
    try:
        client = InsecureClient(HDFS_URL, user='ubuntu')
        return client
    except Exception as e:
        logger.error(f"HDFS 연결 실패: {e}")
        raise HTTPException(status_code=500, detail=f"HDFS 연결 실패: {str(e)}")

cleanup_status = {
    "is_running": False,
    "start_time": None,
    "end_time": None,
    "total_es_docs": 0,
    "invalid_es_docs": 0,
    "deleted_es_docs": 0,
    "deleted_hdfs_images": 0,
    "error": None
}

status_lock = threading.Lock()

async def run_cleanup_task(batch_size: int = 1000, dry_run: bool = False):
    global cleanup_status
    with status_lock:
        if cleanup_status["is_running"]:
            return
        cleanup_status.update({
            "is_running": True,
            "start_time": datetime.now().isoformat(),
            "end_time": None,
            "total_es_docs": 0,
            "invalid_es_docs": 0, 
            "deleted_es_docs": 0,
            "deleted_hdfs_images": 0,
            "error": None
        })
    try:
        conn = get_db_connection()
        es = get_es_client()
        hdfs_client = get_hdfs_client()
        mysql_ids = set()
        with conn.cursor() as cursor:
            cursor.execute("SELECT management_id FROM found_item")
            for row in cursor.fetchall():
                mysql_ids.add(row['management_id'])
        logger.info(f"MySQL에서 {len(mysql_ids)}개의 management_id 로드됨")
        invalid_es_docs = []
        total_es_docs = 0
        scroll_resp = es.search(
            index=ES_INDEX,
            scroll='5m',
            size=batch_size,
            body={
                "_source": ["management_id", "mysql_id"],
                "query": {"match_all": {}}
            }
        )
        scroll_id = scroll_resp['_scroll_id']
        es_batch = scroll_resp['hits']['hits']
        while len(es_batch) > 0:
            total_es_docs += len(es_batch)
            for doc in es_batch:
                source = doc.get('_source', {})
                management_id = source.get('management_id')
                if not management_id or management_id not in mysql_ids:
                    invalid_es_docs.append({
                        "_id": doc['_id'],
                        "management_id": management_id
                    })
            with status_lock:
                cleanup_status.update({
                    "total_es_docs": total_es_docs,
                    "invalid_es_docs": len(invalid_es_docs)
                })
            scroll_resp = es.scroll(scroll_id=scroll_id, scroll='5m')
            scroll_id = scroll_resp['_scroll_id']
            es_batch = scroll_resp['hits']['hits']
        deleted_es_docs = 0
        if not dry_run and invalid_es_docs:
            delete_actions = [{
                "_op_type": "delete",
                "_index": ES_INDEX,
                "_id": doc["_id"]
            } for doc in invalid_es_docs]
            if delete_actions:
                deleted_count, errors = helpers.bulk(es, delete_actions, stats_only=True)
                deleted_es_docs = deleted_count
                if errors:
                    logger.warning(f"Elasticsearch 문서 삭제 중 {errors}개의 오류 발생")
            logger.info(f"{deleted_es_docs}개의 Elasticsearch 문서 삭제됨")
            with status_lock:
                cleanup_status.update({
                    "deleted_es_docs": deleted_es_docs
                })
        deleted_hdfs_images = 0
        if not dry_run:
            try:
                for doc in invalid_es_docs:
                    management_id = doc.get("management_id")
                    if management_id:
                        hdfs_image_pattern = f"/found_items/images/*{management_id}*.jpg"
                        try:
                            matched_files = hdfs_client.list("/found_items/images/")
                            for file in matched_files:
                                if management_id in file:
                                    file_path = f"/found_items/images/{file}"
                                    hdfs_client.delete(file_path)
                                    deleted_hdfs_images += 1
                        except Exception as e:
                            logger.error(f"HDFS 파일 검색 중 오류: {e}")
                logger.info(f"{deleted_hdfs_images}개의 HDFS 이미지 파일 삭제됨")
                with status_lock:
                    cleanup_status.update({
                        "deleted_hdfs_images": deleted_hdfs_images
                    })
            except Exception as e:
                logger.error(f"HDFS 이미지 삭제 중 오류: {e}")
    except Exception as e:
        logger.error(f"클린업 작업 중 오류 발생: {e}")
        import traceback
        logger.error(f"상세 오류: {traceback.format_exc()}")
        with status_lock:
            cleanup_status.update({"error": str(e)})
    finally:
        with status_lock:
            cleanup_status.update({
                "is_running": False,
                "end_time": datetime.now().isoformat()
            })
        try:
            if conn:
                conn.close()
        except:
            pass

@router.post("/sync")
async def sync_data_stores(
    background_tasks: BackgroundTasks,
    batch_size: int = Query(1000, ge=100, le=10000, description="처리할 배치 크기"),
    dry_run: bool = Query(False, description="변경 사항을 적용하지 않고 확인만 수행")
):
    global cleanup_status
    with status_lock:
        if cleanup_status["is_running"]:
            return {
                "status": "running",
                "message": "이미 클린업 작업이 실행 중입니다.",
                "current_status": cleanup_status
            }
    background_tasks.add_task(run_cleanup_task, batch_size, dry_run)
    return {
        "status": "started",
        "message": f"데이터 정합성 유지 작업이 시작되었습니다. dry_run: {dry_run}",
        "dry_run": dry_run
    }

@router.get("/status")
async def get_cleanup_status():
    with status_lock:
        status_copy = cleanup_status.copy()
    return {
        "status": "running" if status_copy["is_running"] else "idle",
        "details": status_copy
    }
