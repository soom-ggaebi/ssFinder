import os
import uvicorn
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.models.models import LostItemAnalyzer
from app.routers.img_analyze_router import router as img_analyze_router

# 전역 변수로 분석 선언
analyzer = None

# Lifespan
from contextlib import asynccontextmanager

# lifespan 컨텍스트 매니저 추가
@asynccontextmanager
async def lifespan(app: FastAPI):
    # 앱 시작 시 실행
    global analyzer
    analyzer = LostItemAnalyzer()
    print("분실물 분석 ai가 초기화되었습니다.")

    yield  # 애플리케이션 실행 지점
    
    print("분실물 분석 ai가 종료되었습니다.")

# FastAPI 앱 생성
app = FastAPI(title="분실물 이미지 분석 API", lifespan=lifespan)

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 실제 배포 시 도메인 제한 필요
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# API 라우터 등록
app.include_router(img_analyze_router)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))

    # 서버 실행
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
