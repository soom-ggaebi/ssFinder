"""
환경변수, 공통변수를 관리하는 파일
"""

# config/config.py
import os
from dotenv import load_dotenv

load_dotenv()  # .env 파일을 사용한다면

# FastAPI 설정
FAST_API_HOST = os.getenv("FAST_API_HOST", "0.0.0.0")
FAST_API_PORT = int(os.getenv("FAST_API_PORT", 8000))

# 공공데이터 API 서비스 키
API_SERVICE_KEY = os.getenv("API_SERVICE_KEY")

# Kafka 설정
KAFKA_BROKER = os.getenv("KAFKA_BROKER", "kafka:9092")
KAFKA_BULK_TOPIC = os.getenv("KAFKA_BULK_TOPIC", "lostfund_bulk")
KAFKA_DETAIL_TOPIC = os.getenv("KAFKA_DETAIL_TOPIC", "lostfund_detail")

# MySQL 설정
DB_HOST = os.getenv("DB_HOST", "mysql")
DB_PORT = int(os.getenv("DB_PORT", 3306))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
DB_NAME = os.getenv("DB_NAME", "lostfound")

# Hadoop/HDFS (Spark에서 hdfs://hadoop-namenode:9000/... 식으로 접근)
HADOOP_NAMENODE_HOST = os.getenv("HADOOP_NAMENODE_HOST", "hadoop-namenode")
HADOOP_NAMENODE_PORT = 9000

# S3 (또는 MinIO) 설정
S3_ENDPOINT_URL = os.getenv("S3_ENDPOINT_URL", "http://minio:9000")
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY", "minioadmin")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_KEY", "minioadmin")
AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
AWS_S3_BUCKET = os.getenv("AWS_S3_BUCKET", "my-bucket")

# Elasticsearch 설정
ES_HOST = os.getenv("ES_HOST", "elasticsearch")
ES_PORT = int(os.getenv("ES_PORT", 9200))
ES_INDEX = os.getenv("ES_INDEX", "found_items")
