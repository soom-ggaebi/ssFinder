from fastapi import APIRouter, BackgroundTasks
from app.core.producer_bulk import run_full_pipeline
from app.models.response.ApiResponse import ApiResponse
import app.models.response.Status as Status

# 각 단계별 테스트 함수 임포트
from app.core.test_summary import test_summary_api_and_kafka
from app.core.test_detail_service import test_detail_api_and_kafka
from app.core.test_spark_streaming import test_spark_streaming
from app.core.test_batch_job import test_batch_job

router = APIRouter()

@router.get("/lost-items", response_model=ApiResponse[str])
def run_pipeline(background_tasks: BackgroundTasks):
    """
    GET 요청 시 전체 파이프라인(공공데이터 API 호출 → Kafka 전송 → Spark 작업 → MySQL/S3/Hadoop 저장)을
    백그라운드에서 실행합니다.
    """
    background_tasks.add_task(run_full_pipeline)
    return ApiResponse(
        status=Status.SUCCESS, 
        message="Full pipeline job started in background.", 
        data=""
    )

@router.get("/summary", response_model=ApiResponse[str])
def test_summary(background_tasks: BackgroundTasks):
    """
    GET 요청 시 요약 데이터 수집 및 Kafka 전송 기능을 테스트합니다.
    """
    background_tasks.add_task(test_summary_api_and_kafka)
    return ApiResponse(
        status=Status.SUCCESS, 
        message="Summary data producer job executed.", 
        data=""
    )

@router.get("/detail", response_model=ApiResponse[str])
def test_detail(background_tasks: BackgroundTasks):
    """
    GET 요청 시 상세 정보 API 호출 및 Kafka 전송 기능을 테스트합니다.
    (기본 관리번호: FTEST001 사용)
    """
    default_management_id = "FTEST001"
    background_tasks.add_task(test_detail_api_and_kafka, default_management_id)
    return ApiResponse(
        status=Status.SUCCESS, 
        message="Detail data producer job executed.", 
        data=""
    )

@router.get("/spark", response_model=ApiResponse[str])
def test_spark(background_tasks: BackgroundTasks):
    """
    GET 요청 시 Spark Streaming 작업을 테스트합니다.
    """
    background_tasks.add_task(test_spark_streaming)
    return ApiResponse(
        status=Status.SUCCESS, 
        message="Spark streaming job executed.", 
        data=""
    )

@router.get("/batch", response_model=ApiResponse[str])
def test_batch(background_tasks: BackgroundTasks):
    """
    GET 요청 시 Spark Batch Job (요약+상세 결합) 작업을 테스트합니다.
    """
    background_tasks.add_task(test_batch_job)
    return ApiResponse(
        status=Status.SUCCESS, 
        message="Batch job executed.", 
        data=""
    )
