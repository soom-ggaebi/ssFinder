import os
import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from models import LostItemAnalyzer
from routers import api

# FastAPI 앱 생성
app = FastAPI(title="분실물 이미지 분석 API")

# CORS 설정
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 실제 배포 시 도메인 제한 필요
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 전역 변수로 분석기 선언 (앱 시작시 한 번만 로드)
analyzer = None

# 앱 시작시 실행되는 이벤트 핸들러러
@app.on_event("startup")
async def startup_event():
    global analyzer
    analyzer = LostItemAnalyzer()
    print("분실물 분석 ai가 초기화되었습니다.")

# API 라우터 등록
app.include_router(api.router)

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))

    # 서버 실행
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
