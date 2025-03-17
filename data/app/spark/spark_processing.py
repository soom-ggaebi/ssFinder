from pyspark.sql import SparkSession
from pyspark.sql.functions import from_json, col, udf
from pyspark.sql.types import StructType, StructField, StringType
import requests
from io import BytesIO
from PIL import Image
import base64
import boto3
import mysql.connector
from elasticsearch import Elasticsearch
import json
import os

from config.config import (
    KAFKA_BROKER, KAFKA_BULK_TOPIC, KAFKA_DETAIL_TOPIC,
    DB_HOST, DB_PORT, DB_USER, DB_PASSWORD, DB_NAME,
    S3_ENDPOINT_URL, AWS_ACCESS_KEY, AWS_SECRET_KEY, AWS_S3_BUCKET,
    ES_HOST, ES_PORT, ES_INDEX
)

# Spark 세션
spark = SparkSession.builder.appName("LostFoundSparkProcessing").getOrCreate()

# 1) Kafka에서 BULK 토픽 구독
df_bulk = spark.readStream.format("kafka") \
    .option("kafka.bootstrap.servers", KAFKA_BROKER) \
    .option("subscribe", KAFKA_BULK_TOPIC) \
    .option("startingOffsets", "earliest") \
    .load()

# 2) Kafka에서 DETAIL 토픽 구독
df_detail = spark.readStream.format("kafka") \
    .option("kafka.bootstrap.servers", KAFKA_BROKER) \
    .option("subscribe", KAFKA_DETAIL_TOPIC) \
    .option("startingOffsets", "earliest") \
    .load()

# 메시지 스키마 (간단화)
schema = StructType([
    StructField("type", StringType(), True),
    StructField("timestamp", StringType(), True),
    StructField("data", StringType(), True)  # data 자체를 문자열로 처리
])

def parse_kafka_df(df):
    return df.selectExpr("CAST(value AS STRING) as json_str") \
             .select(from_json(col("json_str"), schema).alias("parsed")) \
             .select("parsed.*")

parsed_bulk = parse_kafka_df(df_bulk)
parsed_detail = parse_kafka_df(df_detail)

# ------------ 이미지 전처리 UDF 예시 -------------
def process_image(img_url: str):
    if not img_url:
        return None
    try:
        resp = requests.get(img_url)
        resp.raise_for_status()
        img = Image.open(BytesIO(resp.content))
        img = img.resize((256, 256))
        buffer = BytesIO()
        img.save(buffer, format="JPEG", quality=85)
        buffer.seek(0)
        return base64.b64encode(buffer.read()).decode('utf-8')
    except:
        return None

process_image_udf = udf(process_image, StringType())

# Bulk/Detail 공통으로 data를 JSON으로 파싱해 필드를 추출하기 위한 UDF
def parse_data(json_str: str):
    try:
        return json.loads(json_str)
    except:
        return {}

parse_data_udf = udf(parse_data, 
    StructType([
        StructField("atcId", StringType(), True),
        StructField("fdFilePathImg", StringType(), True),
        StructField("clrNm", StringType(), True),
        StructField("fdPrdtNm", StringType(), True),
        StructField("fdYmd", StringType(), True),
        StructField("depPlace", StringType(), True),
        StructField("fdSn", StringType(), True),
        # 필요하면 더 많은 필드를 정의
    ])
)

bulk_enriched = parsed_bulk \
    .withColumn("json_data", parse_data_udf(col("data"))) \
    .withColumn("image_url", col("json_data.fdFilePathImg")) \
    .withColumn("processed_image", process_image_udf(col("image_url")))

detail_enriched = parsed_detail \
    .withColumn("json_data", parse_data_udf(col("data"))) \
    .withColumn("image_url", col("json_data.fdFilePathImg")) \
    .withColumn("processed_image", process_image_udf(col("image_url")))

# ------------ foreachBatch 저장 로직 -------------
def store_batch_bulk(batch_df, batch_id):
    """
    BULK 데이터(간략 정보) 저장 로직:
      - 이미지 전처리 결과 -> S3
      - 메타데이터 -> MySQL, Hadoop(HDFS), Elasticsearch
    """
    pdf = batch_df.toPandas()
    
    # S3 클라이언트
    s3 = boto3.client(
        's3',
        endpoint_url=S3_ENDPOINT_URL,
        aws_access_key_id=AWS_ACCESS_KEY,
        aws_secret_access_key=AWS_SECRET_KEY,
        region_name="us-east-1"
    )
    # MySQL 연결
    mysql_conn = mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )
    cursor = mysql_conn.cursor()
    # Elasticsearch 연결
    es = Elasticsearch([f"http://{ES_HOST}:{ES_PORT}"])

    for _, row in pdf.iterrows():
        row_type = row['type']           # "BULK"
        atc_id = row['json_data']['atcId']
        image_base64 = row['processed_image']
        dep_place = row['json_data']['depPlace']
        fd_prdt_nm = row['json_data']['fdPrdtNm']
        clr_nm = row['json_data']['clrNm']
        fd_ymd = row['json_data']['fdYmd']
        
        # 1) S3에 업로드
        if image_base64:
            image_bytes = base64.b64decode(image_base64)
            s3_key = f"bulk/{atc_id}.jpg"
            s3.put_object(Bucket=AWS_S3_BUCKET, Key=s3_key, Body=image_bytes, ContentType="image/jpeg")

        # 2) MySQL에 저장 (예시: found_item 테이블)
        insert_query = """
            INSERT INTO found_item (management_id, name, color, location, stored_at, created_at)
            VALUES (%s, %s, %s, %s, %s, NOW())
        """
        cursor.execute(insert_query, (atc_id, fd_prdt_nm, clr_nm, dep_place, "STORED"))
        mysql_conn.commit()

        # 3) HDFS 저장 (Spark DF write -> Parquet) : 아래에서 일괄 저장
        #  (개별 로우 접근 대신, 아래 batch_df.write 사용 권장)

        # 4) Elasticsearch 인덱싱
        doc = {
            "atcId": atc_id,
            "depPlace": dep_place,
            "fdPrdtNm": fd_prdt_nm,
            "clrNm": clr_nm,
            "fdYmd": fd_ymd,
            "timestamp": row['timestamp'],
            "type": row_type
        }
        es.index(index=ES_INDEX, body=doc)

    # HDFS 저장: Spark DF -> Parquet (bulk path)
    # (batch_df는 Spark DF 형태로 들어오므로, pandas 변환 전 DF를 받아서 저장하는 게 더 좋음)
    # 간단 예: batch_df.write.mode("append").parquet("hdfs://hadoop-namenode:9000/data/found_items/bulk")
    # 여기서는 pandas 변환 전 DF가 필요하므로 구조 조정이 필요함

    cursor.close()
    mysql_conn.close()

def store_batch_detail(batch_df, batch_id):
    """
    DETAIL 데이터(상세 정보) 저장 로직
      - 유사한 방식으로 S3/MySQL/HDFS/ES 저장
    """
    pdf = batch_df.toPandas()

    s3 = boto3.client(
        's3',
        endpoint_url=S3_ENDPOINT_URL,
        aws_access_key_id=AWS_ACCESS_KEY,
        aws_secret_access_key=AWS_SECRET_KEY,
        region_name="us-east-1"
    )
    mysql_conn = mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )
    cursor = mysql_conn.cursor()
    es = Elasticsearch([f"http://{ES_HOST}:{ES_PORT}"])

    for _, row in pdf.iterrows():
        row_type = row['type']           # "DETAIL"
        atc_id = row['json_data']['atcId']
        image_base64 = row['processed_image']
        dep_place = row['json_data']['depPlace']
        fd_prdt_nm = row['json_data']['fdPrdtNm']
        clr_nm = row['json_data']['clrNm']
        fd_ymd = row['json_data']['fdYmd']
        
        # S3 업로드
        if image_base64:
            image_bytes = base64.b64decode(image_base64)
            s3_key = f"detail/{atc_id}.jpg"
            s3.put_object(Bucket=AWS_S3_BUCKET, Key=s3_key, Body=image_bytes, ContentType="image/jpeg")

        # MySQL 갱신/추가 (예시: found_item 테이블 업데이트)
        update_query = """
            UPDATE found_item
            SET updated_at = NOW(), color = %s
            WHERE management_id = %s
        """
        cursor.execute(update_query, (clr_nm, atc_id))
        mysql_conn.commit()

        # Elasticsearch 인덱싱 (상세 정보 업데이트)
        doc = {
            "atcId": atc_id,
            "depPlace": dep_place,
            "fdPrdtNm": fd_prdt_nm,
            "clrNm": clr_nm,
            "fdYmd": fd_ymd,
            "timestamp": row['timestamp'],
            "type": row_type
        }
        es.index(index=ES_INDEX, body=doc)

    # HDFS 저장 (detail path)
    # (마찬가지로 batch_df.write를 사용하려면 Spark DF 그대로 받아야 함)
    # batch_df.write.mode("append").parquet("hdfs://hadoop-namenode:9000/data/found_items/detail")

    cursor.close()
    mysql_conn.close()

# writeStream foreachBatch
query_bulk = bulk_enriched.writeStream.foreachBatch(store_batch_bulk).start()
query_detail = detail_enriched.writeStream.foreachBatch(store_batch_detail).start()

# 데이터가 없더라도 스트리밍 작업이 종료되지 않도록 대기합니다.
query_bulk.awaitTermination()
query_detail.awaitTermination()
