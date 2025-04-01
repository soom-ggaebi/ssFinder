"""
FastAPI 애플리케이션 메인 파일
REST API 엔드포인트를 제공합니다.
"""
import logging
import os
from fastapi import FastAPI, HTTPException, Depends, Query, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from typing import Optional
from datetime import datetime
from pydantic import BaseModel

from core.pipeline import run_pipeline
from api import api_router
from config.config import FAST_API_HOST, FAST_API_PORT

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# FastAPI 앱 생성
app = FastAPI(
    title="데이터 파이프라인 API",
    description="분실물 데이터 수집 및 처리 파이프라인 API",
    version="1.0.0"
)

# CORS 미들웨어 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 라우터 등록
app.include_router(api_router, prefix="/api")

# 파이프라인 상태 관리
pipeline_status = {
    "is_running": False,
    "start_time": None,
    "end_time": None,
    "status": "idle",
    "message": "",
}

# 모델 정의
class PipelineStatus(BaseModel):
    is_running: bool
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    status: str
    message: str

def get_pipeline_status():
    """현재 파이프라인 상태 반환"""
    return pipeline_status

def run_pipeline_task(start_date: Optional[str] = None, end_date: Optional[str] = None, 
                     sequential_mode: bool = False):
    """백그라운드 태스크로 파이프라인 실행"""
    global pipeline_status
    
    pipeline_status["is_running"] = True
    pipeline_status["start_time"] = datetime.now()
    pipeline_status["status"] = "running"
    pipeline_status["message"] = "파이프라인 실행 중"
    
    try:
        # register_signals=False로 설정하여 signal 핸들러를 등록하지 않음
        run_pipeline(start_date, end_date, sequential_mode, register_signals=False)
        pipeline_status["status"] = "completed"
        pipeline_status["message"] = "파이프라인 실행 완료"
    except Exception as e:
        logger.error(f"파이프라인 실행 중 에러 발생: {e}")
        pipeline_status["status"] = "failed"
        pipeline_status["message"] = f"파이프라인 에러: {str(e)}"
    finally:
        pipeline_status["is_running"] = False
        pipeline_status["end_time"] = datetime.now()

@app.get("/", tags=["상태"])
async def root():
    """API 루트 경로"""
    return {"message": "데이터 파이프라인 API 서비스에 연결되었습니다."}

@app.get("/status", response_model=PipelineStatus, tags=["상태"])
async def status(status_data: dict = Depends(get_pipeline_status)):
    """현재 파이프라인 상태 조회"""
    return status_data

@app.post("/pipeline/start", response_model=PipelineStatus, tags=["파이프라인"])
async def start_pipeline(
    background_tasks: BackgroundTasks,
    start_date: Optional[str] = Query(None, description="데이터 수집 시작일 (YYYYMMDD 형식)"),
    end_date: Optional[str] = Query(None, description="데이터 수집 종료일 (YYYYMMDD 형식)"),
    sequential: bool = Query(False, description="순차 실행 모드 (프로듀서 완료 후 다른 서비스 시작)")
):
    """파이프라인 실행 시작"""
    status_data = get_pipeline_status()
    
    if status_data["is_running"]:
        raise HTTPException(status_code=400, detail="파이프라인이 이미 실행 중입니다.")
    
    # 날짜 형식 검증
    if start_date:
        try:
            datetime.strptime(start_date, "%Y%m%d")
        except ValueError:
            raise HTTPException(status_code=400, detail="start_date의 형식이 올바르지 않습니다. YYYYMMDD 형식이어야 합니다.")
    
    if end_date:
        try:
            datetime.strptime(end_date, "%Y%m%d")
        except ValueError:
            raise HTTPException(status_code=400, detail="end_date의 형식이 올바르지 않습니다. YYYYMMDD 형식이어야 합니다.")
    
    # 백그라운드 태스크로 파이프라인 실행
    background_tasks.add_task(run_pipeline_task, start_date, end_date, sequential)
    
    return get_pipeline_status()

@app.post("/pipeline/stop", response_model=PipelineStatus, tags=["파이프라인"])
async def stop_pipeline():
    """현재 실행 중인 파이프라인 중지 (미구현)"""
    status_data = get_pipeline_status()
    
    if not status_data["is_running"]:
        raise HTTPException(status_code=400, detail="현재 실행 중인 파이프라인이 없습니다.")
    
    # 파이프라인 중지 기능은 현재 버전에서 구현되지 않음
    return {
        **status_data,
        "message": "파이프라인 중지 기능은 현재 버전에서 지원되지 않습니다."
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=FAST_API_HOST,
        port=FAST_API_PORT,
        reload=True
    )