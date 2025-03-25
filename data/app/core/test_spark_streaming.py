# test_spark_streaming.py

import os
import json
import requests
import uuid
from io import BytesIO
from PIL import Image
import boto3
from pyspark.sql import SparkSession
from pyspark.sql.functions import col, udf
from pyspark.sql.types import StructType, StructField, StringType
from config.config import SPARK_MASTER


# 드라이버에서 S3 관련 환경 변수 읽기 (UDF 내부에서 사용할 클로저 변수)
AWS_S3_BUCKET = os.getenv("AWS_S3_BUCKET")
AWS_REGION = os.getenv("AWS_REGION")
AWS_ACCESS_KEY = os.getenv("AWS_ACCESS_KEY")
AWS_SECRET_KEY = os.getenv("AWS_SECRET_KEY")

def process_and_upload_image(image_url: str) -> str:
    try:
        response = requests.get(image_url, stream=True, timeout=10)
        response.raise_for_status()
        img_data = BytesIO(response.content)
        img = Image.open(img_data)
        # 256x256 크기로 리사이즈
        img = img.resize((256, 256))
        buffer = BytesIO()
        img.save(buffer, format="JPEG")
        buffer.seek(0)
    except Exception as e:
        print(f"Error processing image {image_url}: {e}")
        return image_url  # 에러 발생 시 원본 URL 반환

    try:
        # S3 클라이언트 생성 (환경 변수는 클로저로 전달됨)
        s3 = boto3.client(
            "s3",
            aws_access_key_id=AWS_ACCESS_KEY,
            aws_secret_access_key=AWS_SECRET_KEY,
            region_name=AWS_REGION
        )
        key = f"processed_images/{uuid.uuid4().hex}.jpg"
        s3.upload_fileobj(buffer, AWS_S3_BUCKET, key, ExtraArgs={"ContentType": "image/jpeg"})
        s3_url = f"https://{AWS_S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{key}"
        return s3_url
    except Exception as e:
        print(f"Error uploading image to S3: {e}")
        return image_url

# UDF 생성: process_and_upload_image를 문자열 리턴 UDF로 등록
process_and_upload_image_udf = udf(process_and_upload_image, StringType())

def test_spark_streaming():
    # Spark 세션 생성 (로컬 모드 사용; 필요에 따라 SPARK_MASTER 값을 변경)
    spark = SparkSession.builder \
        .appName("TestSparkStreaming") \
        .master(SPARK_MASTER) \
        .getOrCreate()

    # 테스트용 샘플 데이터 (Kafka에서 받는 JSON 구조와 동일)
    sample_data = [
        {
            "management_id": "F2025032200000093",
            "color": "블랙",
            "stored_at": "테스트경찰서",
            "image": "https://entertainimg.kbsmedia.co.kr/cms/uploads/CONTENTS_20230425095757_b457a570577d7444e7cef5c0a6e73bd7.png",
            "name": "테스트 물품",
            "found_at": "2025-03-15 00:00:00",
            "prdtClNm": "테스트 > 샘플",
            "status": "STORED",
            "location": "테스트장소",
            "phone": "010-1234-5678",
            "detail": "테스트 상세정보"
        }
    ]

    # JSON 문자열로 변환하여 RDD 생성 후 DataFrame으로 읽기
    rdd = spark.sparkContext.parallelize([json.dumps(item) for item in sample_data])
    df = spark.read.json(rdd)

    # (옵션) 스키마 정의: 이미 JSON 데이터에서 추론되지만 명시적으로 지정할 경우
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

    # UDF를 사용하여 "image" 컬럼으로부터 S3 URL 생성하여 "s3_image" 컬럼 추가
    df = df.withColumn("s3_image", process_and_upload_image_udf(col("image")))

    # 결과 출력
    df.show(truncate=False)

    # 최종 데이터 저장 (로컬 파일 시스템에 JSON 형식으로 저장)
    output_path = "/tmp/test_spark_streaming_output"
    df.write.mode("overwrite").json(output_path)
    print(f"Spark Streaming 테스트 결과를 {output_path}에 저장하였습니다.")

    spark.stop()

if __name__ == "__main__":
    test_spark_streaming()
