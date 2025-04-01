"""
애플리케이션 설정 모듈
환경 변수와 설정값을 관리합니다.
"""
import os
from dotenv import load_dotenv

# 환경 변수 로드
load_dotenv()

# FastAPI 설정
FAST_API_HOST = os.getenv("FAST_API_HOST", "0.0.0.0")
FAST_API_PORT = int(os.getenv("FAST_API_PORT", 8000))

# 공공데이터 API 설정
API_SERVICE_KEY = os.getenv("API_SERVICE_KEY", "")

# Kafka 설정
KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
KAFKA_TOPIC_SUMMARY = os.getenv("KAFKA_TOPIC_SUMMARY", "summary_topic")
KAFKA_TOPIC_ID = os.getenv("KAFKA_TOPIC_ID", "id_topic")
KAFKA_TOPIC_DETAIL = os.getenv("KAFKA_TOPIC_DETAIL", "detail_topic")
KAFKA_TOPIC_IMAGE_PROCESSING = "image_processing"
KAFKA_TOPIC_PROCESSED_DATA = "processed_data"
KAFKA_TOPIC_IMAGE_METADATA = "image_metadata"
KAFKA_TOPIC_COMPLETE_DATA = "complete_data"

# Spark 설정
SPARK_MASTER = os.getenv("SPARK_MASTER", "local[*]")

# MySQL 데이터베이스 설정
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = int(os.getenv("DB_PORT", 3306))
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "ssfinder")

# HDFS 설정
HDFS_NAMENODE = os.getenv("HDFS_NAMENODE", "localhost")
HDFS_PORT = int(os.getenv("HDFS_PORT", 9000))
HDFS_URL = os.getenv("HDFS_URL", "http://localhost:9870/webhdfs/v1")

# S3 설정
S3_BUCKET = os.getenv("S3_BUCKET", "")
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY", "")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_KEY", "")
AWS_REGION = os.getenv("AWS_REGION", "")

# Elasticsearch 설정
ES_HOST = os.getenv("ES_HOST", "localhost")
ES_PORT = int(os.getenv("ES_PORT", 9200))
ES_INDEX = os.getenv("ES_INDEX", "found-items")

# 지오코딩 API 설정
GEOCODING_API_KEY = os.getenv("GEOCODING_API_KEY", "")

# 동시성 설정
DEFAULT_THREAD_POOL_SIZE = os.cpu_count() * 2 if os.cpu_count() else 8
API_THREAD_POOL_SIZE = int(os.getenv("API_THREAD_POOL_SIZE", DEFAULT_THREAD_POOL_SIZE))
PROCESSING_THREAD_POOL_SIZE = int(os.getenv("PROCESSING_THREAD_POOL_SIZE", DEFAULT_THREAD_POOL_SIZE * 2))
IO_THREAD_POOL_SIZE = int(os.getenv("IO_THREAD_POOL_SIZE", DEFAULT_THREAD_POOL_SIZE * 4))

# 배치 처리 설정
KAFKA_BATCH_SIZE = int(os.getenv("KAFKA_BATCH_SIZE", 100))
HDFS_BATCH_SIZE = int(os.getenv("HDFS_BATCH_SIZE", 5000))
HDFS_FLUSH_INTERVAL = int(os.getenv("HDFS_FLUSH_INTERVAL", 300))  # 초 단위

# API 요청 설정
API_RETRY_COUNT = int(os.getenv("API_RETRY_COUNT", 3))
API_TIMEOUT = int(os.getenv("API_TIMEOUT", 100))  # 초 단위
API_BATCH_SIZE = int(os.getenv("API_BATCH_SIZE", 1000))

# 이미지 처리 설정
IMAGE_RESIZE_WIDTH = int(os.getenv("IMAGE_RESIZE_WIDTH", 512))
IMAGE_RESIZE_HEIGHT = int(os.getenv("IMAGE_RESIZE_HEIGHT", 512))

ES_BULK_FLUSH_INTERVAL = 300
ES_BULK_BATCH_SIZE = 500