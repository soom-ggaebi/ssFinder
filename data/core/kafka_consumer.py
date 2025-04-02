import json
import os
import time
import threading
import logging
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
    ES_BULK_BATCH_SIZE, ES_BULK_FLUSH_INTERVAL  # Bulk 관련 설정 (예: 100, 10초)
)

logger = logging.getLogger(__name__)

# HDFS 배치 관련 설정 (기존 코드 유지)
hdfs_lock = threading.Lock()
hdfs_batch_buffer = []
last_flush_time = time.time()

# Elasticsearch Bulk 작업을 위한 전역 큐와 락
es_bulk_queue = []
es_bulk_lock = threading.Lock()
last_es_flush_time = time.time()

# DBUtils PooledDB를 사용한 MySQL 연결 풀 (한 번만 초기화)
pool = PooledDB(
    creator=pymysql,
    maxconnections=20,
    mincached=5,
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
)

def get_db_connection():
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

@run_in_thread_pool(pool_type='processing')
def get_or_create_category(category_name, parent_id, level):
    conn = None
    try:
        conn = get_db_connection()
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
            conn.commit()
            return category_id
    except Exception as e:
        logger.error(f"카테고리 조회/생성 에러: {e}")
        import traceback
        logger.error(f"상세 오류: {traceback.format_exc()}")
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

@run_in_thread_pool(pool_type='processing')
def insert_into_mysql(message):
    conn = None
    try:
        management_id = message.get('management_id')
        logger.info(f"MySQL 연결 시도: {DB_HOST}:{DB_PORT} (management_id={management_id})")
        conn = get_db_connection()
        logger.info(f"MySQL 연결 성공 (management_id={management_id})")
        
        if not management_id:
            logger.error("management_id가 없어 MySQL에 저장할 수 없습니다.")
            return None
        
        if not message.get('name'):
            message['name'] = '미확인 물품'
            logger.warning(f"{management_id}: 물품명이 없어 기본값 설정")
            
        if not message.get('stored_at'):
            message['stored_at'] = '미확인 위치'
            logger.warning(f"{management_id}: 보관장소가 없어 기본값 설정")
            
        if not message.get('status'):
            message['status'] = 'STORED'
            logger.warning(f"{management_id}: 상태가 없어 기본값 설정")
        
        try:
            with conn.cursor() as cursor:
                select_sql = "SELECT id FROM found_item WHERE management_id = %s"
                logger.info(f"중복 확인 SQL 실행 (management_id={management_id}): {select_sql}")
                cursor.execute(select_sql, (management_id,))
                row = cursor.fetchone()
                if row:
                    logger.info(f"이미 존재하는 관리번호: {management_id}, mysql_id: {row['id']}")
                    message['mysql_id'] = row['id']
                    return row['id']
                logger.info(f"중복 확인 완료: 신규 레코드 (management_id={management_id})")
        except Exception as e:
            logger.error(f"중복 확인 중 오류 발생 ({management_id}): {e}")
            import traceback
            logger.error(f"상세 오류: {traceback.format_exc()}")
            raise

        logger.info(f"카테고리 처리 시작 (management_id={management_id})")
        category_id = None
        try:
            prdtClNm = message.get('prdtClNm', '')
            if prdtClNm:
                logger.info(f"상품 카테고리: {prdtClNm} (management_id={management_id})")
                category_parts = [part.strip() for part in prdtClNm.split('>') if part.strip()]
                if category_parts:
                    parent_name = category_parts[0]
                    logger.info(f"상위 카테고리 조회/생성: {parent_name} (management_id={management_id})")
                    parent_id = get_or_create_category(parent_name, None, "MAJOR")
                    logger.info(f"상위 카테고리 ID: {parent_id} (management_id={management_id})")
                    message['category_major'] = parent_name
                    if len(category_parts) > 1:
                        child_name = category_parts[1]
                        logger.info(f"하위 카테고리 조회/생성: {child_name} (parent_id={parent_id}, management_id={management_id})")
                        category_id = get_or_create_category(child_name, parent_id, "MINOR")
                        logger.info(f"하위 카테고리 ID: {category_id} (management_id={management_id})")
                        message['category_minor'] = child_name
                    else:
                        message['category_minor'] = None
                        category_id = parent_id
                        logger.info(f"하위 카테고리 없음, 상위 카테고리 ID 사용: {category_id} (management_id={management_id})")
        except Exception as e:
            logger.error(f"카테고리 처리 에러 ({management_id}): {e}")
            import traceback
            logger.error(f"상세 오류: {traceback.format_exc()}")
            logger.info(f"기본 카테고리 조회 시도 (management_id={management_id})")
            category_id = get_default_category_id(conn)
            logger.info(f"기본 카테고리({category_id})를 사용합니다. (management_id={management_id})")
        
        if category_id is None:
            logger.info(f"카테고리 ID가 없어 기본 카테고리 조회 시도 (management_id={management_id})")
            category_id = get_default_category_id(conn)
            logger.info(f"카테고리 ID가 없어 기본 카테고리({category_id})를 사용합니다. (management_id={management_id})")
            
        logger.info(f"위치 정보 처리 시작 (management_id={management_id})")
        latitude = message.get('latitude')
        longitude = message.get('longitude')
        
        logger.info(f"원본 위도/경도: {latitude}, {longitude} (management_id={management_id})")
        if latitude is not None and longitude is not None:
            if abs(latitude) > 90:
                temp = latitude
                latitude = longitude
                longitude = temp
                message['latitude'] = latitude
                message['longitude'] = longitude
                logger.warning(f"SQL 실행 전 위도/경도 교정: 위도={latitude}, 경도={longitude} (management_id={management_id})")
            
            if abs(latitude) > 90 or abs(longitude) > 180:
                logger.warning(f"최종 위도/경도({latitude}, {longitude})가 유효하지 않아 기본값으로 설정 (management_id={management_id})")
                latitude = 37.5665
                longitude = 126.9780
                message['latitude'] = latitude
                message['longitude'] = longitude
        else:
            logger.warning(f"위도/경도 정보 없음, 기본값 설정 (management_id={management_id})")
            latitude = 37.5665
            longitude = 126.9780
            message['latitude'] = latitude
            message['longitude'] = longitude
        
        logger.info(f"최종 위도/경도: {latitude}, {longitude} (management_id={management_id})")

        try:
            with conn.cursor() as cursor:
                sql = """
                    INSERT INTO found_item 
                    (management_id, name, color, stored_at, image, found_at, item_category_id, status, location, coordinates, phone, detail, created_at)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, ST_PointFromText(CONCAT('POINT(', %s, ' ', %s, ')'), 4326), %s, %s, %s)
                """
                params = (
                    message.get('management_id'),
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
                    datetime.utcnow()
                )
                
                # 로그 메시지가 너무 길어지지 않도록 일부 내용만 로깅
                param_log = f"management_id={params[0]}, name={params[1]}, category_id={params[6]}, status={params[7]}, lat={params[9]}, lon={params[10]}"
                logger.info(f"SQL 실행 시도 (management_id={management_id}): {sql}")
                logger.info(f"SQL 파라미터 주요 정보: {param_log}")
                
                try:
                    cursor.execute(sql, params)
                    auto_id = cursor.lastrowid
                    logger.info(f"SQL 실행 성공, lastrowid={auto_id} (management_id={management_id})")
                except Exception as sql_error:
                    logger.error(f"SQL 실행 오류 ({management_id}): {sql_error}")
                    import traceback
                    logger.error(f"SQL 오류 상세: {traceback.format_exc()}")
                    # SQL 예외 정보 더 자세히 로깅
                    if hasattr(sql_error, 'args'):
                        logger.error(f"SQL 오류 인자: {sql_error.args}")
                    raise
            
            logger.info(f"MySQL commit 시도 (management_id={management_id})")
            try:
                conn.commit()
                logger.info(f"MySQL commit 성공 (management_id={management_id})")
            except Exception as commit_error:
                logger.error(f"MySQL commit 오류 ({management_id}): {commit_error}")
                import traceback
                logger.error(f"Commit 오류 상세: {traceback.format_exc()}")
                if conn:
                    try:
                        conn.rollback()
                        logger.info(f"MySQL 롤백 완료 (commit 실패로 인한): {management_id}")
                    except Exception as rollback_error:
                        logger.error(f"MySQL 롤백 실패: {rollback_error}")
                raise commit_error
            
            message['mysql_id'] = auto_id
            logger.info(f"MySQL 저장 완료: management_id={management_id}, id={auto_id}")
            return auto_id
        except Exception as e:
            logger.error(f"데이터 삽입 에러 ({management_id}): {e}")
            import traceback
            logger.error(f"상세 오류: {traceback.format_exc()}")
            if conn:
                try:
                    conn.rollback()
                    logger.info(f"MySQL 롤백 완료: {management_id}")
                except Exception as rollback_error:
                    logger.error(f"MySQL 롤백 실패: {rollback_error}")
            raise
    except Exception as e:
        logger.error(f"MySQL 저장 에러: {e}")
        import traceback
        logger.error(f"상세 오류: {traceback.format_exc()}")
        if conn:
            try:
                conn.rollback()
                logger.info(f"최상위 예외 처리에서 롤백 완료")
            except Exception as rollback_error:
                logger.error(f"최상위 예외 처리에서 롤백 실패: {rollback_error}")
        raise
    finally:
        if conn:
            try:
                conn.close()
                logger.info(f"MySQL 연결 닫힘 (management_id={management_id if 'management_id' in message else 'unknown'})")
            except Exception as conn_close_error:
                logger.error(f"MySQL 연결 닫기 실패: {conn_close_error}")

def prepare_message_for_elasticsearch(message):
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
    
    if 'created_at' in message and hasattr(message['created_at'], 'isoformat'):
        message['created_at'] = message['created_at'].isoformat()
    
    if 'fdSn' in message:
        del message['fdSn']
    
    if 'found_at' in message and message['found_at'] is not None:
        try:
            if isinstance(message['found_at'], str):
                found_at_date = datetime.strptime(message['found_at'], '%Y-%m-%d %H:%M:%S')
                message['found_at'] = found_at_date.isoformat()
        except ValueError:
            message['found_at'] = None
    
    if 'prdtClNm' in message:
         del message['prdtClNm']
    
    return message

# Bulk API를 위한 Elasticsearch 저장 함수
def flush_es_bulk():
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
            "_op_type": "index",  # 문서가 이미 존재하면 실패합니다.
            "_index": ES_INDEX,
            "_id": doc_id,
            "_source": message
        })
    try:
        es = Elasticsearch(
            hosts=[{'host': ES_HOST, 'port': ES_PORT, 'scheme': 'http'}],
            timeout=30
        )
        success, failed = helpers.bulk(es, actions, stats_only=True)
        logger.info(f"Bulk Elasticsearch 저장 성공: {success} 건, 실패: {failed} 건")
        last_es_flush_time = time.time()
    except Exception as e:
        logger.error(f"Bulk Elasticsearch 저장 에러: {e}")
        # 실패 시 문서들을 다시 큐에 추가할 수 있습니다.
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
    while True:
        time.sleep(10)
        try:
            flush_hdfs_batch()
        except Exception as e:
            logger.error(f"HDFS 주기적 플러시 에러: {e}")

@run_in_thread_pool(pool_type='processing')
def process_message(message):
    try:
        management_id = message.get('management_id')
        logger.info(f"메시지 처리 시작: {management_id}")
        
        # 1. 이미지 처리
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
        
        # 2. 지오코딩 처리
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
                            message['latitude'] = 0
                            message['longitude'] = 0
                            logger.warning(f"비정상 위치 좌표, 기본값(0,0) 사용: ({lat}, {lon})")
                else:
                    message['latitude'] = 0
                    message['longitude'] = 0
                    logger.warning("지오코딩 결과 없음, 기본값 사용")
            except Exception as e:
                logger.error(f"지오코딩 에러 ({management_id}): {e}")
                message['latitude'] = 0
                message['longitude'] = 0
        else:
            message['latitude'] = 0
            message['longitude'] = 0

        # 3. 색상 처리
        original_color = message.get('color', '')
        if original_color:
            try:
                matched_color = match_color_fuzzy(original_color)
                message['color'] = matched_color
                logger.debug(f"색상 처리: {original_color} -> {matched_color}")
            except Exception as e:
                logger.error(f"색상 매칭 에러 ({management_id}): {e}")
        
        # 4. MySQL 저장
        try:
            mysql_id = insert_into_mysql(message)
            if mysql_id:
                message['mysql_id'] = mysql_id
        except Exception as e:
            logger.error(f"MySQL 저장 중 에러 ({management_id}): {e}")
        
        # 5. Elasticsearch 저장 (Bulk API 방식으로 저장 큐에 추가)
        try:
            insert_into_elasticsearch(message)
        except Exception as e:
            logger.error(f"Elasticsearch 저장 중 에러 ({management_id}): {e}")
        
        # 6. HDFS 배치 버퍼에 추가
        with hdfs_lock:
            hdfs_batch_buffer.append(message)
            if len(hdfs_batch_buffer) >= HDFS_BATCH_SIZE:
                threading.Thread(target=flush_hdfs_batch).start()
        
        logger.info(f"메시지 처리 완료: {management_id}")
        return True
    except Exception as e:
        logger.error(f"메시지 처리 중 에러 발생: {e}")
        return False

def run_kafka_consumer_continuous():
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
    
    # Elasticsearch Bulk 작업을 위한 별도 플러시 스레드
    def es_bulk_flush_loop():
        while True:
            time.sleep(ES_BULK_FLUSH_INTERVAL if 'ES_BULK_FLUSH_INTERVAL' in globals() else 10)
            flush_es_bulk()
    threading.Thread(target=es_bulk_flush_loop, daemon=True).start()
    
    pool_manager = ThreadPoolManager()
    message_queue = BackpressureQueue(max_size=1000, blocking=True)
    futures = []
    processing_count = 0
    max_concurrent_tasks = min(os.cpu_count() * 4, 20)
    
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
                message = json.loads(message_value)
                management_id = message.get('management_id')
                message_queue.put(message)
                logger.debug(f"메시지 큐에 추가: {management_id}")
                if message_queue.size() % 100 == 0:
                    logger.info(f"현재 큐 크기: {message_queue.size()}, 처리 중 작업: {processing_count}")
                consumer.commit(asynchronous=True)
            except Exception as e:
                logger.error(f"메시지 처리 중 에러 발생: {e}")
                import traceback
                logger.error(f"상세 오류: {traceback.format_exc()}")
    except KeyboardInterrupt:
        logger.info("소비자 중단 요청 감지")
    finally:
        logger.info("Kafka 소비자 종료 및 리소스 정리 중...")
        flush_hdfs_batch()
        consumer.close()
        for f in futures:
            try:
                f.result(timeout=10)
            except Exception:
                pass
        logger.info("Kafka 소비자 종료 완료")

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO,
                       format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    run_kafka_consumer_continuous()
