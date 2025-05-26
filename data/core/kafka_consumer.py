"""
Kafka 컨슈머 모듈
큐 기반 순차 처리를 통해 MySQL 저장의 안정성 향상
빈 메시지 수신 시 전체 파이프라인 종료와 종료 후 추가 로그 발생 방지를 구현함.
"""

import json
import os
import time
import threading
import logging
import queue
import pymysql
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from confluent_kafka import Consumer, KafkaException
from elasticsearch import Elasticsearch, helpers  # helpers.bulk 사용
from pymysql.cursors import DictCursor
from dbutils.pooled_db import PooledDB  # DBUtils

from core.image_processing import process_and_upload_image_opencv
from core.geocoding import geocode_location
from core.color_matching import match_color_fuzzy
from core.kafka_producer import send_to_kafka
from utils.concurrency import ThreadPoolManager, BackpressureQueue, run_in_thread_pool
from config.config import (
    KAFKA_BOOTSTRAP_SERVERS, KAFKA_TOPIC_DETAIL, KAFKA_TOPIC_IMAGE_PROCESSING,
    KAFKA_TOPIC_PROCESSED_DATA, KAFKA_TOPIC_IMAGE_METADATA, KAFKA_TOPIC_COMPLETE_DATA,
    DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME,
    S3_BUCKET, AWS_ACCESS_KEY, AWS_SECRET_KEY, AWS_REGION,
    HDFS_NAMENODE, HDFS_PORT, HDFS_URL,
    ES_HOST, ES_PORT, ES_INDEX,
    HDFS_BATCH_SIZE, HDFS_FLUSH_INTERVAL,
    ES_BULK_BATCH_SIZE, ES_BULK_FLUSH_INTERVAL 
)

# Elasticsearch 인증정보 (환경변수 설정)
ES_USERNAME = os.getenv("ES_USERNAME")
ES_PASSWORD = os.getenv("ES_PASSWORD")

logger = logging.getLogger(__name__)

# HDFS 배치 관련 설정
hdfs_lock = threading.Lock()
hdfs_batch_buffer = []
last_flush_time = time.time()

# Elasticsearch Bulk 작업을 위한 전역 큐와 락
es_bulk_queue = []
es_bulk_lock = threading.Lock()
last_es_flush_time = time.time()

# MySQL 작업 큐와 워커 스레드 제어 이벤트
mysql_queue = queue.Queue()
mysql_worker_stop_event = threading.Event()

# DBUtils PooledDB를 사용한 MySQL 연결 풀 
pool = PooledDB(
    creator=pymysql,
    maxconnections=10,      # 동시 연결 수 제한
    mincached=2,            # 최소 캐시 연결 수
    maxcached=5,            # 최대 캐시 연결 수
    maxshared=5,            # 최대 공유 연결 수
    blocking=True,
    host=DB_HOST,
    port=DB_PORT,
    user=DB_USER,
    password=DB_PASSWORD,
    database=DB_NAME,
    charset='utf8mb4',
    cursorclass=DictCursor,
    autocommit=False,
    connect_timeout=10,
    read_timeout=30,
    write_timeout=30,
    ping=1                 
)

def get_db_connection():
    """데이터베이스 연결 획득"""
    try:
        conn = pool.connection()
        with conn.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
        return conn
    except Exception as e:
        logger.error(f"DB 연결 실패: {e}")
        raise

def get_default_category_id(conn):
    """기본 카테고리 ID 조회 또는 생성"""
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id FROM item_category WHERE name = '기타' AND level = 'MAJOR'")
            row = cursor.fetchone()
            if row:
                return row['id']
            cursor.execute(
                "INSERT INTO item_category (parent_id, name, level) VALUES (NULL, '기타', 'MAJOR')"
            )
            conn.commit()
            return cursor.lastrowid
    except Exception as e:
        logger.error(f"기본 카테고리 조회/생성 에러: {e}")
        if conn:
            try:
                conn.rollback()
            except:
                pass
        return 1

def get_or_create_category(conn, category_name, parent_id, level):
    """카테고리 조회 또는 생성 (conn을 파라미터로 받음)"""
    try:
        with conn.cursor() as cursor:
            select_sql = """
                SELECT id 
                FROM item_category 
                WHERE name = %s COLLATE utf8mb4_general_ci AND (parent_id <=> %s) AND level = %s
            """
            cursor.execute(select_sql, (category_name, parent_id, level))
            row = cursor.fetchone()
            if row:
                return row['id']
            insert_sql = """
                INSERT INTO item_category (parent_id, name, level)
                VALUES (%s, %s, %s)
            """
            cursor.execute(insert_sql, (parent_id, category_name, level))
            category_id = cursor.lastrowid
            return category_id
    except Exception as e:
        logger.error(f"카테고리 조회/생성 에러: {e}")
        raise

def process_category(conn, message):
    """카테고리 처리 함수 (conn을 파라미터로 받음)"""
    default_category_id = get_default_category_id(conn)
    try:
        prdtClNm = message.get('prdtClNm', '')
        if not prdtClNm:
            return default_category_id
        category_parts = [part.strip() for part in prdtClNm.split('>') if part.strip()]
        if not category_parts:
            return default_category_id
        parent_name = category_parts[0]
        parent_id = get_or_create_category(conn, parent_name, None, "MAJOR")
        message['category_major'] = parent_name
        if len(category_parts) == 1:
            message['category_minor'] = None
            return parent_id
        child_name = category_parts[1]
        category_id = get_or_create_category(conn, child_name, parent_id, "MINOR")
        message['category_minor'] = child_name
        return category_id
    except Exception as e:
        logger.error(f"카테고리 처리 중 예외 발생: {e}")
        return default_category_id

def insert_into_mysql_directly(message):
    """
    MySQL에 직접 저장하는 함수
    (mysql_worker_thread에서만 호출되며, 큐를 통한 순차 처리를 위함)
    """
    conn = None
    try:
        management_id = message.get('management_id')
        logger.info(f"MySQL 연결 시도: {management_id}")
        conn = get_db_connection()
        logger.info(f"MySQL 연결 성공: {management_id}")
        if not management_id:
            logger.error("management_id가 없어 MySQL에 저장할 수 없습니다.")
            return None
        if not message.get('name'):
            message['name'] = '미확인 물품'
        if not message.get('stored_at'):
            message['stored_at'] = '미확인 위치'
        if not message.get('status'):
            message['status'] = 'STORED'
        with conn.cursor() as cursor:
            select_sql = "SELECT id FROM found_item WHERE management_id = %s"
            cursor.execute(select_sql, (management_id,))
            row = cursor.fetchone()
            if row:
                logger.info(f"이미 존재하는 관리번호: {management_id}, mysql_id: {row['id']}")
                return row['id']
        category_id = process_category(conn, message)
        latitude = message.get('latitude', 37.5665)
        longitude = message.get('longitude', 126.9780)
        current_time = datetime.utcnow()
        with conn.cursor() as cursor:
            sql = """
                INSERT INTO found_item 
                (management_id, name, color, stored_at, image, found_at, item_category_id, status, location, coordinates, phone, detail, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, ST_PointFromText(CONCAT('POINT(', %s, ' ', %s, ')'), 4326), %s, %s, %s)
            """
            cursor.execute(sql, (
                management_id,
                message.get('name'),
                message.get('color'),
                message.get('stored_at'),
                message.get('image'),
                message.get('found_at'),
                category_id,
                message.get('status'),
                message.get('location'),
                latitude,
                longitude,
                message.get('phone'),
                message.get('detail'),
                current_time
            ))
            auto_id = cursor.lastrowid
        conn.commit()
        logger.info(f"MySQL 저장 성공: {management_id}, id={auto_id}")
        message['created_at'] = current_time
        return auto_id
    except Exception as e:
        logger.error(f"MySQL 저장 에러: {e}")
        if conn:
            try:
                conn.rollback()
            except:
                pass
        raise
    finally:
        if conn:
            try:
                conn.close()
            except:
                pass

def mysql_worker_thread():
    """MySQL 저장 작업만 처리하는 전용 워커 스레드"""
    logger.info("MySQL 워커 스레드 시작")
    consecutive_errors = 0
    while not mysql_worker_stop_event.is_set():
        try:
            try:
                message, result_callback = mysql_queue.get(timeout=1.0)
            except queue.Empty:
                continue
            management_id = message.get('management_id')
            logger.info(f"MySQL 작업 시작: {management_id}")
            try:
                mysql_id = insert_into_mysql_directly(message)
                consecutive_errors = 0
                if result_callback:
                    result_callback(True, mysql_id, message)
            except Exception as e:
                consecutive_errors += 1
                logger.error(f"MySQL 저장 실패 ({consecutive_errors}번째 연속 오류): {e}")
                if consecutive_errors >= 5:
                    wait_time = min(consecutive_errors * 2, 60)
                    logger.warning(f"{consecutive_errors}번 연속 실패로 {wait_time}초 대기 후 재개")
                    time.sleep(wait_time)
                if result_callback:
                    result_callback(False, None, message)
            mysql_queue.task_done()
        except Exception as e:
            logger.error(f"MySQL 워커 스레드 오류: {e}")
            import traceback
            logger.error(f"상세 오류: {traceback.format_exc()}")
            time.sleep(5)

def handle_mysql_result(success, mysql_id, message):
    """MySQL 저장 작업 결과 처리 콜백"""
    management_id = message.get('management_id')
    if success:
        message['mysql_id'] = mysql_id
        if 'created_at' in message and hasattr(message['created_at'], 'isoformat'):
            message['created_at'] = message['created_at'].isoformat()
        else:
            message['created_at'] = datetime.utcnow().isoformat()
        message['updated_at'] = None
        logger.info(f"MySQL 저장 성공에 따른 후속 처리: {management_id}")
        try:
            insert_into_elasticsearch(message)
        except Exception as e:
            logger.error(f"Elasticsearch 저장 중 에러: {e}")
        with hdfs_lock:
            hdfs_batch_buffer.append(message)
            if len(hdfs_batch_buffer) >= HDFS_BATCH_SIZE:
                threading.Thread(target=flush_hdfs_batch).start()
    else:
        logger.error(f"MySQL 저장 실패로 후속 처리 건너뜀: {management_id}")

def prepare_message_for_elasticsearch(message):
    """Elasticsearch에 저장할 형식으로 메시지 변환"""
    if 'mysql_id' in message and message['mysql_id'] is not None:
        message['mysql_id'] = str(message['mysql_id'])
    lat = None
    lon = None
    for field in ['latitude', 'longitude']:
        if field in message and message[field] is not None:
            try:
                value = float(message[field])
                message[field] = value
                if field == 'latitude':
                    lat = value
                else:
                    lon = value
            except ValueError:
                message[field] = None
    if lat is not None and lon is not None:
         message['location_geo'] = {"lat": lat, "lon": lon}
    else:
         message['location_geo'] = None
    if 'created_at' in message:
        if hasattr(message['created_at'], 'isoformat'):
            message['created_at'] = message['created_at'].isoformat()
    message['updated_at'] = None
    if 'found_at' in message and message['found_at'] is not None:
        try:
            if len(message['found_at']) == 10:
                found_at_date = datetime.strptime(message['found_at'], '%Y-%m-%d')
            else:
                found_at_date = datetime.strptime(message['found_at'], '%Y-%m-%d %H:%M:%S')
            message['found_at'] = found_at_date.isoformat()
        except ValueError:
            message['found_at'] = None
    if 'fdSn' in message:
        del message['fdSn']
    if 'prdtClNm' in message:
         del message['prdtClNm']
    return message

def flush_es_bulk():
    """Elasticsearch Bulk 큐의 데이터를 일괄 처리"""
    global es_bulk_queue, last_es_flush_time
    with es_bulk_lock:
        if not es_bulk_queue:
            return
        documents = es_bulk_queue.copy()
        es_bulk_queue = []
    actions = []
    for message in documents:
        message = prepare_message_for_elasticsearch(message)
        doc_id = message.get('mysql_id') if message.get('mysql_id') is not None else message.get('management_id')
        doc_id = str(doc_id)
        actions.append({
            "_op_type": "index",  
            "_index": ES_INDEX,
            "_id": doc_id,
            "_source": message
        })
    try:
        es = Elasticsearch(
            hosts=[{'host': ES_HOST, 'port': ES_PORT, 'scheme': 'http'}],
            http_auth=(ES_USERNAME, ES_PASSWORD) if ES_USERNAME and ES_PASSWORD else None,
            timeout=30
        )
        success, failed = helpers.bulk(es, actions, stats_only=True)
        logger.info(f"Bulk Elasticsearch 저장 성공: {success} 건, 실패: {failed} 건")
        last_es_flush_time = time.time()
    except Exception as e:
        logger.error(f"Bulk Elasticsearch 저장 에러: {e}")
        with es_bulk_lock:
            es_bulk_queue.extend(documents)

@run_in_thread_pool(pool_type='io')
def insert_into_elasticsearch(message):
    """단건 저장 대신 Bulk API 사용을 위해 메시지는 es_bulk_queue에 추가"""
    with es_bulk_lock:
        es_bulk_queue.append(message)
    logger.info(f"Elasticsearch 저장 큐에 추가: management_id={message.get('management_id')}")
    return True

def flush_hdfs_batch():
    """HDFS 배치 버퍼의 데이터를 HDFS에 저장"""
    global hdfs_batch_buffer, last_flush_time
    logger.debug("flush_hdfs_batch 시작")
    with hdfs_lock:
        if not hdfs_batch_buffer:
            logger.debug("HDFS 배치 버퍼 비어 있음")
            return
        buffer_copy = hdfs_batch_buffer.copy()
        hdfs_batch_buffer = []
    try:
        from hdfs import InsecureClient
        client = InsecureClient(HDFS_URL, user='ubuntu')
        file_path = "/found_items/processed/found_item.csv"
        directory = "/found_items/processed"
        try:
            if not client.status(directory, strict=False):
                logger.info(f"HDFS 디렉토리 생성: {directory}")
                client.makedirs(directory)
        except Exception as e:
            logger.info(f"디렉토리 확인 중 예외 발생, 생성 시도: {e}")
            client.makedirs(directory)
        def escape_csv_field(field):
            if field is None:
                return ""
            if isinstance(field, (dict, list)):
                field = json.dumps(field, ensure_ascii=False)
            field = str(field).replace("\n", " ").replace("\r", " ")
            if '"' in field:
                field = field.replace('"', '""')
            return f'"{field}"'
        headers = list(buffer_copy[0].keys())
        header_line = ",".join([f'"{h}"' for h in headers])
        lines = []
        for msg in buffer_copy:
            row_values = [escape_csv_field(msg.get(key, "")) for key in headers]
            lines.append(",".join(row_values))
        batch_content = "\n".join(lines) + "\n"
        try:
            file_exists = client.status(file_path, strict=False) is not None
            content_to_write = batch_content if file_exists else header_line + "\n" + batch_content
        except:
            content_to_write = header_line + "\n" + batch_content
        try:
            with client.write(file_path, append=file_exists, encoding='utf-8') as writer:
                writer.write(content_to_write)
        except Exception as e:
            if "not found" in str(e):
                logger.info(f"파일 생성: {file_path}")
                with client.write(file_path, overwrite=True, encoding='utf-8') as writer:
                    writer.write(content_to_write)
            else:
                raise
        logger.info(f"HDFS에 {len(buffer_copy)}개 메시지 저장 완료: {file_path}")
        last_flush_time = time.time()
        return True
    except Exception as e:
        logger.error(f"HDFS 저장 에러: {e}")
        import traceback
        logger.error(f"상세 오류: {traceback.format_exc()}")
        with hdfs_lock:
            hdfs_batch_buffer.extend(buffer_copy)
        return False

def flush_hdfs_periodically():
    """주기적으로 HDFS 배치 버퍼를 비우는 백그라운드 스레드"""
    while True:
        time.sleep(10)
        try:
            flush_hdfs_batch()
        except Exception as e:
            logger.error(f"HDFS 주기적 플러시 에러: {e}")

@run_in_thread_pool(pool_type='processing')
def process_message(message):
    """
    메시지 처리 로직 (병렬 처리를 위해 스레드 풀에서 실행)
    1. 이미지 처리
    2. 지오코딩
    3. 색상 매칭
    4. MySQL 저장 작업을 큐에 추가 (순차 처리를 위해)
    """
    try:
        management_id = message.get('management_id')
        logger.info(f"메시지 처리 시작: {management_id}")
        image_url = message.get('image')
        if image_url and image_url.startswith("http"):
            if "img02_no_img.gif" in image_url:
                logger.info(f"기본 이미지 감지됨: {image_url} → 전처리 건너뜀")
                message['image'] = None
                message['image_hdfs'] = None
            else:
                try:
                    processed_image = process_and_upload_image_opencv(image_url)
                    message['image'] = processed_image.get("s3_url")
                    message['image_hdfs'] = processed_image.get("hdfs_url")
                except Exception as e:
                    logger.error(f"이미지 처리 에러 ({management_id}): {e}")
                    message['image'] = image_url
                    message['image_hdfs'] = None
        location = message.get('stored_at')
        if location:
            try:
                lat, lon = geocode_location(location)
                if lat is not None and lon is not None:
                    if 32 <= lat <= 44 and 123 <= lon <= 133:
                        message['latitude'] = lat
                        message['longitude'] = lon
                    elif 123 <= lat <= 133 and 32 <= lon <= 44:
                        message['latitude'] = lon
                        message['longitude'] = lat
                        logger.warning(f"위도/경도 교정: ({lat}, {lon}) -> ({lon}, {lat})")
                    else:
                        swapped_lat, swapped_lon = lon, lat
                        if 32 <= swapped_lat <= 44 and 123 <= swapped_lon <= 133:
                            message['latitude'] = swapped_lat
                            message['longitude'] = swapped_lon
                            logger.warning(f"비정상 좌표 교정: ({lat}, {lon}) -> ({swapped_lat}, {swapped_lon})")
                        else:
                            message['latitude'] = 37.5665
                            message['longitude'] = 126.9780
                            logger.warning(f"비정상 위치 좌표, 기본값 사용: ({lat}, {lon})")
                else:
                    message['latitude'] = 37.5665
                    message['longitude'] = 126.9780
                    logger.warning("지오코딩 결과 없음, 기본값 사용")
            except Exception as e:
                logger.error(f"지오코딩 에러 ({management_id}): {e}")
                message['latitude'] = 37.5665
                message['longitude'] = 126.9780
        else:
            message['latitude'] = 37.5665
            message['longitude'] = 126.9780
        original_color = message.get('color', '')
        if original_color:
            try:
                matched_color = match_color_fuzzy(original_color)
                message['color'] = matched_color
                logger.debug(f"색상 처리: {original_color} -> {matched_color}")
            except Exception as e:
                logger.error(f"색상 매칭 에러 ({management_id}): {e}")
        mysql_queue.put((message, handle_mysql_result))
        logger.info(f"MySQL 저장 작업 큐에 추가됨: {management_id}")
        logger.info(f"메시지 전처리 완료 및 MySQL 큐에 추가됨: {management_id}")
        return True
    except Exception as e:
        logger.error(f"메시지 처리 중 에러 발생: {e}")
        return False

def run_kafka_consumer_continuous():
    """Kafka 소비자 실행: 상세 정보가 포함된 메시지를 소비하고 처리"""
    mysql_thread = threading.Thread(target=mysql_worker_thread, daemon=True)
    mysql_thread.start()
    
    consumer_conf = {
        'bootstrap.servers': KAFKA_BOOTSTRAP_SERVERS,
        'group.id': 'lost_items_consumer_group_continuous',
        'auto.offset.reset': 'earliest',
        'enable.auto.commit': 'false',
        'max.poll.interval.ms': 600000,
        'session.timeout.ms': 30000,
        'fetch.max.bytes': 52428800,
        'max.partition.fetch.bytes': 1048576,
        'queued.max.messages.kbytes': 102400
    }
    consumer = Consumer(consumer_conf)
    consumer.subscribe([KAFKA_TOPIC_DETAIL])
    
    flush_thread = threading.Thread(target=flush_hdfs_periodically, daemon=True)
    flush_thread.start()
    
    def es_bulk_flush_loop():
        while True:
            time.sleep(ES_BULK_FLUSH_INTERVAL if 'ES_BULK_FLUSH_INTERVAL' in globals() else 10)
            flush_es_bulk()
    threading.Thread(target=es_bulk_flush_loop, daemon=True).start()
    
    pool_manager = ThreadPoolManager()
    message_queue = BackpressureQueue(max_size=1000, blocking=True)
    futures = []
    processing_count = 0
    max_concurrent_tasks = min(os.cpu_count() * 2, 10)
    
    def consume_tasks():
        nonlocal processing_count
        while True:
            try:
                message = message_queue.get()
                future = pool_manager.submit_to_processing_pool(process_message, message)
                futures.append(future)
                processing_count += 1
                completed_futures = []
                for f in futures:
                    if f.done():
                        completed_futures.append(f)
                        try:
                            f.result()
                        except Exception as e:
                            logger.error(f"작업 처리 중 예외 발생: {e}")
                        finally:
                            processing_count -= 1
                for f in completed_futures:
                    futures.remove(f)
                message_queue.task_done()
            except Exception as e:
                logger.error(f"작업 소비자 에러: {e}")
                import traceback
                logger.error(f"상세 오류: {traceback.format_exc()}")
    
    for _ in range(4):
        t = threading.Thread(target=consume_tasks, daemon=True)
        t.start()
    
    try:
        logger.info("Kafka 소비자 시작")
        while True:
            if processing_count >= max_concurrent_tasks:
                time.sleep(0.1)
                continue
            msg = consumer.poll(timeout=1.0)
            if msg is None:
                continue
            if msg.error():
                err_str = str(msg.error())
                if "EOF" in err_str:
                    continue
                logger.error(f"Kafka 에러: {msg.error()}")
                continue
            try:
                message_value = msg.value().decode('utf-8')
                # 빈 메시지(또는 공백만 있는 경우)가 오면 파이프라인 종료를 시작합니다.
                if not message_value.strip():
                    logger.info("빈 메시지 감지됨 – 파이프라인 종료 시작")
                    break
                message = json.loads(message_value)
                management_id = message.get('management_id')
                message_queue.put(message)
                if message_queue.size() % 100 == 0:
                    logger.info(f"현재 큐 크기: {message_queue.size()}, 처리 중: {processing_count}, MySQL 큐: {mysql_queue.qsize()}")
                consumer.commit(asynchronous=True)
            except Exception as e:
                logger.error(f"메시지 처리 중 에러 발생: {e}")
                import traceback
                logger.error(f"상세 오류: {traceback.format_exc()}")
    except KeyboardInterrupt:
        logger.info("소비자 중단 요청 감지")
    finally:
        logger.info("Kafka 소비자 종료 및 리소스 정리 시작")
        mysql_worker_stop_event.set()
        if not mysql_queue.empty():
            logger.info(f"남은 MySQL 작업 {mysql_queue.qsize()}개 처리 대기 중...")
            mysql_queue.join()
        flush_hdfs_batch()
        flush_es_bulk()
        consumer.close()
        ThreadPoolManager().shutdown()
        for f in futures:
            try:
                f.result(timeout=10)
            except Exception:
                pass
        logger.info("Kafka 소비자 종료 완료")
        # 필요시 아래와 같이 명시적 프로세스 종료를 호출할 수 있습니다.
        # import sys
        # sys.exit(0)

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO,
                      format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    run_kafka_consumer_continuous()
