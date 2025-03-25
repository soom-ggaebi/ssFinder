"""
환경변수, 공통변수를 관리하는 파일
"""

import os
from dotenv import load_dotenv

load_dotenv()  # .env 파일을 로드

# FastAPI 설정
FAST_API_HOST = os.getenv("FAST_API_HOST", "0.0.0.0")
FAST_API_PORT = int(os.getenv("FAST_API_PORT", 8000))
API_SERVICE_KEY = os.getenv("API_SERVICE_KEY")

# Kafka 설정
KAFKA_BROKER = os.getenv("KAFKA_BOOTSTRAP_SERVERS", "kafka:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC_SUMMARY", "lost_items")
KAFKA_BOOTSTRAP_SERVERS = os.getenv("KAFKA_BOOTSTRAP_SERVERS")
KAFKA_TOPIC_SUMMARY = os.getenv("KAFKA_TOPIC_SUMMARY")
KAFKA_TOPIC_ID = os.getenv("KAFKA_TOPIC_ID")
KAFKA_TOPIC_DETAIL = os.getenv("KAFKA_TOPIC_DETAIL")

# Spark 설정
SPARK_MASTER = os.getenv("SPARK_MASTER")

# MySQL 설정
DB_HOST = os.getenv("DB_HOST")
DB_PORT = int(os.getenv("DB_PORT"))
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")

# HDFS 설정
# .env에서 HDFS_NAMENODE와 HDFS_PORT로 지정되어 있으므로 이를 그대로 사용
HDFS_NAMENODE = os.getenv("HDFS_NAMENODE")
HDFS_PORT = os.getenv("HDFS_PORT")
# 필요에 따라 HDFS를 접속할 때 아래와 같이 사용할 수 있습니다.

HADOOP_NAMENODE_HOST = HDFS_NAMENODE
HADOOP_NAMENODE_PORT = HDFS_PORT
HDFS_URL = os.getenv("HDFS_URL")

# S3 설정
AWS_S3_BUCKET = os.getenv("S3_BUCKET")
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_KEY")
AWS_REGION = os.getenv("AWS_REGION")

# Elasticsearch 설정
ES_HOST = os.getenv("ES_HOST")
ES_PORT = os.getenv("ES_PORT")
ES_INDEX = os.getenv("ES_INDEX")
