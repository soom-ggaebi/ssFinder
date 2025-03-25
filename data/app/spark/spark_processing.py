import os
import requests
import uuid
from io import BytesIO
from PIL import Image
import boto3
import logging
import time

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, from_json, udf
from pyspark.sql.types import StructType, StructField, StringType
from config.config import SPARK_MASTER, KAFKA_BROKER, KAFKA_TOPIC, DB_HOST, DB_USER, DB_PASSWORD, DB_NAME, AWS_S3_BUCKET, HADOOP_NAMENODE_HOST, HADOOP_NAMENODE_PORT

from app.hadoop.hadoop_integration import write_to_hadoop  # 필요시 사용

# 로깅 설정 (한번만 설정)
logger = logging.getLogger("SparkJob")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
handler.setFormatter(formatter)
if not logger.handlers:
    logger.addHandler(handler)

# 이미지 다운로드, 리사이즈, 그리고 AWS S3 업로드 함수
def process_and_upload_image(image_url: str) -> str:
    try:
        response = requests.get(image_url, stream=True, timeout=10)
        response.raise_for_status()
        img_data = BytesIO(response.content)
        img = Image.open(img_data)
        # 예시: 256x256 크기로 리사이즈
        img = img.resize((256, 256))
        buffer = BytesIO()
        img.save(buffer, format="JPEG")
        buffer.seek(0)
    except Exception as e:
        print(f"Error processing image {image_url}: {e}")
        return image_url  # 에러 발생 시 원본 URL 반환

    try:
        # AWS S3 클라이언트 생성 (엔드포인트 미지정 시 기본 AWS S3 사용)
        s3 = boto3.client(
            "s3",
            aws_access_key_id=os.getenv("AWS_ACCESS_KEY"),
            aws_secret_access_key=os.getenv("AWS_SECRET_KEY"),
            region_name=os.getenv("AWS_REGION")
        )
        bucket = os.getenv("AWS_S3_BUCKET")
        key = f"processed_images/{uuid.uuid4().hex}.jpg"
        s3.upload_fileobj(buffer, bucket, key, ExtraArgs={"ContentType": "image/jpeg"})
        s3_url = f"https://{bucket}.s3.{os.getenv('AWS_REGION')}.amazonaws.com/{key}"
        return s3_url
    except Exception as e:
        print(f"Error uploading image to S3: {e}")
        return image_url

# UDF 생성
process_and_upload_image_udf = udf(process_and_upload_image, StringType())

def run_spark_job():
    spark = SparkSession.builder \
        .appName("LostItemsSparkJob") \
        .master(SPARK_MASTER) \
        .getOrCreate()

    # Kafka 메시지 스키마 정의
    schema = StructType([
        StructField("management_id", StringType()),
        StructField("color", StringType()),
        StructField("stored_at", StringType()),
        StructField("image", StringType()),
        StructField("name", StringType()),
        StructField("found_at", StringType()),
        StructField("prdtClNm", StringType()),
        StructField("status", StringType()),
        StructField("location", StringType()),
        StructField("phone", StringType()),
        StructField("detail", StringType())
    ])

    # Kafka에서 메시지 읽기
    df = spark.readStream \
        .format("kafka") \
        .option("kafka.bootstrap.servers", KAFKA_BROKER) \
        .option("subscribe", KAFKA_TOPIC) \
        .option("startingOffsets", "earliest") \
        .load()

    df = df.selectExpr("CAST(value AS STRING) as json_str")
    df = df.select(from_json(col("json_str"), schema).alias("data")).select("data.*")

    # 이미지 처리: 다운로드, 리사이즈 후 AWS S3 업로드
    df = df.withColumn("s3_image", process_and_upload_image_udf(col("image")))

    # 최종 DataFrame 선택 (필요한 컬럼, s3_image 컬럼 추가)
    final_df = df.select("management_id", "name", "color", "stored_at", "s3_image", "found_at",
                           "prdtClNm", "status", "location", "phone", "detail")

    # MySQL 저장 (JDBC 방식)
    mysql_url = f"jdbc:mysql://{DB_HOST}:3306/{DB_NAME}?useSSL=false&serverTimezone=UTC"
    mysql_properties = {
        "user": DB_USER,
        "password": DB_PASSWORD,
        "driver": "com.mysql.cj.jdbc.Driver"
    }

    def write_to_mysql(batch_df, batch_id):
        batch_df.write.jdbc(url=mysql_url, table="found_item", mode="append", properties=mysql_properties)
        logger.info(f"Batch {batch_id} written to MySQL.")

    # S3 저장 (Parquet 형식 – spark-hadoop-aws 설정 필요)
    def write_to_s3(batch_df, batch_id):
        s3_path = f"s3a://{AWS_S3_BUCKET}/lost_items/processed/batch_{batch_id}"
        batch_df.write.mode("append").parquet(s3_path)
        logger.info(f"Batch {batch_id} written to S3 at {s3_path}.")

    # Hadoop(HDFS) 저장 (CSV 형식 예시)
    def write_to_hadoop_local(batch_df, batch_id):
        hadoop_path = f"hdfs://{HADOOP_NAMENODE_HOST}:{HADOOP_NAMENODE_PORT}/lost_items/processed/batch_{batch_id}"
        batch_df.write.mode("append").csv(hadoop_path)
        logger.info(f"Batch {batch_id} written to Hadoop at {hadoop_path}.")

    def process_batch(batch_df, batch_id):
        try:
            count = batch_df.count()
            logger.info(f"Batch {batch_id} count: {count}")
            if count > 0:
                write_to_mysql(batch_df, batch_id)
                write_to_s3(batch_df, batch_id)
                write_to_hadoop_local(batch_df, batch_id)
        except Exception as e:
            logger.error(f"Error processing batch {batch_id}: {e}")

    query = final_df.writeStream \
        .option("checkpointLocation", f"hdfs://{HADOOP_NAMENODE_HOST}:{HADOOP_NAMENODE_PORT}/spark-checkpoints") \
        .foreachBatch(process_batch) \
        .outputMode("append") \
        .start()

    # 스트리밍 쿼리의 상태를 주기적으로 확인하는 루프 예시
    while query.isActive:
        logger.info("Streaming query is active...")
        time.sleep(10)

    logger.error("Streaming query terminated unexpectedly: " + query.status)

    query.awaitTermination()
