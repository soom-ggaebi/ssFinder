import json
import os
import csv
import time
import pymysql
import boto3
from confluent_kafka import Consumer, KafkaException
from config.config import (KAFKA_BROKER, KAFKA_TOPIC,
                           DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME,
                           AWS_S3_BUCKET, AWS_ACCESS_KEY, AWS_SECRET_KEY, AWS_REGION,
                           HDFS_URL)
from hdfs import InsecureClient
from pymysql.cursors import DictCursor

def create_mysql_connection():
    return pymysql.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        charset='utf8mb4',
        use_unicode=True,
        init_command='SET NAMES utf8mb4',
        cursorclass=DictCursor
    )

def get_or_create_category(conn, category_name, parent_id, level):
    with conn.cursor() as cursor:
        select_sql = """
            SELECT id 
            FROM item_category 
            WHERE name = %s COLLATE utf8mb4_general_ci AND (parent_id <=> %s)
        """
        cursor.execute(select_sql, (category_name, parent_id))
        row = cursor.fetchone()
        if row:
            return row['id']
        insert_sql = """
            INSERT INTO item_category (parent_id, name, level)
            VALUES (%s, %s, %s)
        """
        cursor.execute(insert_sql, (parent_id, category_name, level))
        conn.commit()
        return cursor.lastrowid

def insert_into_mysql(message):
    conn = create_mysql_connection()
    try:
        # 제품분류(prdtClNm) 값을 item_category_id로 변환
        category_id = None
        prdtClNm = message.get('prdtClNm', '')
        if prdtClNm:
            category_parts = [part.strip() for part in prdtClNm.split('>') if part.strip()]
            if category_parts:
                parent_name = category_parts[0]
                parent_id = get_or_create_category(conn, parent_name, None, 1)
                if len(category_parts) > 1:
                    child_name = category_parts[1]
                    category_id = get_or_create_category(conn, child_name, parent_id, 2)
                else:
                    category_id = parent_id

        with conn.cursor() as cursor:
            sql = """
                INSERT INTO found_item 
                    (management_id, name, color, stored_at, image, found_at, item_category_id, status, location, phone, detail)
                VALUES 
                    (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """
            cursor.execute(sql, (
                message.get('management_id'),
                message.get('name'),
                message.get('color'),
                message.get('stored_at'),
                message.get('image'),
                message.get('found_at'),
                category_id,
                message.get('status'),
                message.get('location'),
                message.get('phone'),
                message.get('detail')
            ))
        conn.commit()
    except Exception as e:
        print(f"MySQL 저장 에러: {e}")
    finally:
        conn.close()

def upload_to_s3(message, batch_id):
    s3 = boto3.client(
        "s3",
        aws_access_key_id=AWS_ACCESS_KEY,
        aws_secret_access_key=AWS_SECRET_KEY,
        region_name=AWS_REGION
    )
    bucket = AWS_S3_BUCKET
    # management_id를 문자열로 강제 변환합니다.
    key = f"lost_items/processed/batch_{batch_id}/{str(message.get('management_id'))}.json"
    try:
        # JSON 직렬화 후 UTF-8로 인코딩하여 바이트 데이터를 전달합니다.
        s3.put_object(
            Bucket=bucket,
            Key=key,
            Body=json.dumps(message, default=str).encode('utf-8'),
            ContentType="application/json"
        )
        print(f"Uploaded message {message.get('management_id')} to S3 at {key}")
    except Exception as e:
        print(f"S3 업로드 에러: {e}")

def write_to_hdfs(message, batch_id):
    # HDFS_URL의 포트가 실제 네임노드의 WebHDFS 서비스 포트와 일치하는지 확인하세요.
    client = InsecureClient(HDFS_URL, user='root')
    hdfs_path = f"/lost_items/processed/batch_{batch_id}.csv"
    header = list(message.keys())
    line = ",".join([str(message.get(k, "")) for k in header]) + "\n"
    try:
        if client.status(hdfs_path, strict=False):
            with client.write(hdfs_path, append=True, encoding='utf-8') as writer:
                writer.write(line)
        else:
            header_line = ",".join(header) + "\n"
            with client.write(hdfs_path, encoding='utf-8') as writer:
                writer.write(header_line)
                writer.write(line)
        print(f"Written message {message.get('management_id')} to HDFS at {hdfs_path}")
    except Exception as e:
        print(f"HDFS 저장 에러: {e}")

def run_kafka_consumer_batch(max_idle_seconds=10):
    consumer_conf = {
        'bootstrap.servers': KAFKA_BROKER,
        'group.id': 'lost_items_consumer_group_batch',
        'auto.offset.reset': 'earliest'
    }
    consumer = Consumer(consumer_conf)
    consumer.subscribe([KAFKA_TOPIC])
    batch_id = int(time.time())
    idle_start = time.time()
    try:
        while True:
            msg = consumer.poll(timeout=1.0)
            if msg is None:
                if time.time() - idle_start > max_idle_seconds:
                    print(f"No messages for {max_idle_seconds} seconds, stopping consumer batch.")
                    break
                continue
            idle_start = time.time()
            if msg.error():
                raise KafkaException(msg.error())
            message_value = msg.value().decode('utf-8')
            message = json.loads(message_value)
            print(f"Consumed message: {message.get('management_id')}")
            insert_into_mysql(message)
            upload_to_s3(message, batch_id)
            write_to_hdfs(message, batch_id)
    except KeyboardInterrupt:
        print("Kafka consumer interrupted")
    finally:
        consumer.close()

if __name__ == "__main__":
    run_kafka_consumer_batch()
