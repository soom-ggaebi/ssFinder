"""
API 패키지 초기화 모듈
"""
from fastapi import APIRouter
from api.routes import dashboard
from api.routes import cleanup

# API 라우터 생성
api_router = APIRouter()

# 대시보드 라우트 포함
api_router.include_router(dashboard.router)
api_router.include_router(cleanup.router)