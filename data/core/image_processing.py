"""
이미지 처리 모듈
이미지 다운로드, 전처리, S3 및 HDFS 업로드 기능을 제공합니다.

최적화 전략:
1. 비동기 I/O 방식으로 다운로드와 업로드 병렬화
2. 스레드 풀을 활용한 작업 분할
3. 메모리 효율성을 위한 스트리밍 처리
"""
import os
import cv2
import numpy as np
import requests
import uuid
import logging
import io
import boto3
from botocore.config import Config
from hdfs import InsecureClient
from concurrent.futures import ThreadPoolExecutor
from utils.concurrency import run_in_thread_pool
from config.config import (
    S3_BUCKET, AWS_ACCESS_KEY, AWS_SECRET_KEY, AWS_REGION,
    HDFS_URL, HDFS_NAMENODE, HDFS_PORT,
    IMAGE_RESIZE_WIDTH, IMAGE_RESIZE_HEIGHT
)

logger = logging.getLogger(__name__)

# S3 클라이언트 설정
s3_config = Config(
    retries={'max_attempts': 3, 'mode': 'standard'},
    connect_timeout=10,
    read_timeout=30,
    max_pool_connections=20
)

# 캐시된 클라이언트 인스턴스
_s3_client = None
_hdfs_client = None

def get_s3_client():
    """싱글톤 S3 클라이언트 인스턴스 반환"""
    global _s3_client
    if _s3_client is None and AWS_ACCESS_KEY and AWS_SECRET_KEY:
        _s3_client = boto3.client(
            "s3",
            aws_access_key_id=AWS_ACCESS_KEY,
            aws_secret_access_key=AWS_SECRET_KEY,
            region_name=AWS_REGION,
            config=s3_config
        )
    return _s3_client

def get_hdfs_client():
    """싱글톤 HDFS 클라이언트 인스턴스 반환"""
    global _hdfs_client
    if _hdfs_client is None and HDFS_URL:
        _hdfs_client = InsecureClient(HDFS_URL, user="root")
    return _hdfs_client

def adjust_brightness(image, beta=-20):
    """
    이미지 밝기를 조절합니다.
    beta 값이 음수이면 이미지가 어두워집니다.
    """
    return cv2.convertScaleAbs(image, alpha=1.0, beta=beta)

@run_in_thread_pool(pool_type='download')
def download_image(image_url: str) -> np.ndarray:
    """
    이미지 URL에서 이미지를 다운로드합니다. (스레드 풀에서 실행)
    """
    try:
        logger.debug(f"이미지 다운로드 시작: {image_url}")
        response = requests.get(image_url, stream=True, timeout=10)
        response.raise_for_status()
        image_data = np.asarray(bytearray(response.content), dtype=np.uint8)
        img = cv2.imdecode(image_data, cv2.IMREAD_COLOR)
        if img is None:
            raise ValueError("이미지 디코딩 실패")
        logger.debug(f"이미지 다운로드 완료: {image_url}")
        return img
    except Exception as e:
        logger.error(f"이미지 다운로드 에러 ({image_url}): {e}")
        raise

@run_in_thread_pool(pool_type='processing')
def preprocess_image(img: np.ndarray) -> np.ndarray:
    """
    이미지 전처리를 수행합니다. (스레드 풀에서 실행)
    1. LAB 색 공간 변환 및 CLAHE 적용
    2. 언샤프 마스킹을 통한 선명도 개선
    3. 밝기 조절
    4. 리사이징
    """
    try:
        # 1. LAB 색 공간 변환 및 CLAHE 적용 (명암 조정)
        lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
        l_channel, a_channel, b_channel = cv2.split(lab)
        clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
        l_channel_eq = clahe.apply(l_channel)
        lab_eq = cv2.merge((l_channel_eq, a_channel, b_channel))
        enhanced = cv2.cvtColor(lab_eq, cv2.COLOR_LAB2BGR)
        
        # 2. 언샤프 마스킹을 통한 선명도 개선
        gaussian = cv2.GaussianBlur(enhanced, (0, 0), sigmaX=3)
        sharpened = cv2.addWeighted(enhanced, 1.5, gaussian, -0.5, 0)
        
        # 3. 밝기 조절 (어둡게)
        processed = adjust_brightness(sharpened, beta=-20)
        
        # 4. 리사이징
        processed_resized = cv2.resize(processed, (IMAGE_RESIZE_WIDTH, IMAGE_RESIZE_HEIGHT))
        
        return processed_resized
    except Exception as e:
        logger.error(f"이미지 전처리 에러: {e}")
        # 오류 발생 시 원본 이미지 반환
        try:
            return cv2.resize(img, (IMAGE_RESIZE_WIDTH, IMAGE_RESIZE_HEIGHT))
        except:
            return img

@run_in_thread_pool(pool_type='processing')
def encode_image(processed_img: np.ndarray) -> bytes:
    """
    처리된 이미지를 JPEG 형식으로 인코딩합니다. (스레드 풀에서 실행)
    """
    try:
        success, buffer = cv2.imencode('.jpg', processed_img, [cv2.IMWRITE_JPEG_QUALITY, 90])
        if not success:
            raise ValueError("이미지 인코딩 실패")
        return buffer.tobytes()
    except Exception as e:
        logger.error(f"이미지 인코딩 에러: {e}")
        raise

@run_in_thread_pool(pool_type='upload')
def upload_to_s3(image_bytes: bytes) -> str:
    """
    이미지를 S3에 업로드합니다. (스레드 풀에서 실행)
    """
    if not (S3_BUCKET and AWS_ACCESS_KEY and AWS_SECRET_KEY):
        logger.warning("S3 설정이 완료되지 않았습니다.")
        return None
    
    try:
        s3 = get_s3_client()
        if not s3:
            return None
            
        key = f"images/found/{uuid.uuid4().hex}.jpg"
        s3.put_object(
            Bucket=S3_BUCKET, 
            Key=key, 
            Body=image_bytes, 
            ContentType="image/jpeg"
        )
        s3_url = f"https://{S3_BUCKET}.s3.{AWS_REGION}.amazonaws.com/{key}"
        logger.info(f"이미지 S3 업로드 성공: {s3_url}")
        return s3_url
    except Exception as e:
        logger.error(f"S3 업로드 에러: {e}")
        return None

@run_in_thread_pool(pool_type='upload')
def upload_to_hdfs(image_bytes: bytes) -> str:
    """
    이미지를 HDFS에 업로드합니다. (스레드 풀에서 실행)
    """
    if not HDFS_URL:
        logger.warning("HDFS 설정이 완료되지 않았습니다.")
        return None
        
    try:
        client = get_hdfs_client()
        if not client:
            return None
            
        hdfs_path = f"/found_items/images/{uuid.uuid4().hex}.jpg"
        client.write(hdfs_path, data=image_bytes, overwrite=True)
        hdfs_url = f"hdfs://{HDFS_NAMENODE}:{HDFS_PORT}{hdfs_path}"
        logger.info(f"이미지 HDFS 저장 성공: {hdfs_url}")
        return hdfs_url
    except Exception as e:
        logger.error(f"HDFS 업로드 에러: {e}")
        return None

def process_and_upload_image_opencv(image_url: str) -> dict:
    """
    주어진 이미지 URL을 가져와 전처리 후 S3와 HDFS에 업로드합니다.
    
    병렬화된 처리 흐름:
    1. 이미지 다운로드
    2. 이미지 전처리 (CLAHE, 선명도 개선, 밝기 조절)
    3. 이미지 인코딩
    4. S3와 HDFS에 병렬 업로드
    
    업로드 성공 시 S3와 HDFS의 URL을 dict 형태로 반환합니다.
    """
    # 기본 이미지인 경우 처리하지 않음
    if "img02_no_img.gif" in image_url:
        logger.info(f"기본 이미지 감지됨: {image_url} → 전처리 건너뜀")
        return {"s3_url": None, "hdfs_url": None}
        
    try:
        # 1. 이미지 다운로드
        img = download_image(image_url)
        
        # 2. 이미지 전처리
        processed_img = preprocess_image(img)
        
        # 3. 이미지 인코딩
        image_bytes = encode_image(processed_img)
        
        # 4. S3와 HDFS에 병렬 업로드
        with ThreadPoolExecutor(max_workers=2) as executor:
            s3_future = executor.submit(upload_to_s3, image_bytes)
            hdfs_future = executor.submit(upload_to_hdfs, image_bytes)
            
            s3_url = s3_future.result()
            hdfs_url = hdfs_future.result()
        
        return {"s3_url": s3_url, "hdfs_url": hdfs_url}
    except Exception as e:
        logger.error(f"이미지 처리 및 업로드 에러 ({image_url}): {e}")
        return {"s3_url": image_url, "hdfs_url": None}