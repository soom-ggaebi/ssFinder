# main.py
# FastAPI와 메인 실행 모듈

import os
import tempfile
import uvicorn
from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from models import LostItemAnalyzer

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
    print("분실물 분석기가 초기화되었습니다.")

# API 루트 경로 핸들러러
@app.get("/")
async def root():
    return {"message": "분실물 이미지 분석 API가 실행 중입니다."}

# 이미지 분석 후 정보 JSON으로 반환
@app.post("/analyze")
async def analyze_image(file: UploadFile = File(...)):

    global analyzer
    
    if not analyzer:
        raise HTTPException(status_code=500, detail="분석기가 초기화되지 않았습니다.")
    
    try:
        # 임시 파일로 저장
        with tempfile.NamedTemporaryFile(delete=False, suffix=os.path.splitext(file.filename)[1]) as temp:
            temp_path = temp.name
            content = await file.read()
            temp.write(content)
        
        # 이미지 분석
        result = analyzer.analyze_lost_item(temp_path)
        
        # 임시 파일 삭제
        os.unlink(temp_path)
        
        if result["success"]:
            # 한국어 번역 결과만 반환
            ko_result = {
                "status": "success",
                "data": {
                    "title": result["data"]["translated"]["title"],
                    "category": result["data"]["translated"]["category"],
                    "color": result["data"]["translated"]["color"],
                    "material": result["data"]["translated"]["material"],
                    "brand": result["data"]["translated"]["brand"],
                    "description": result["data"]["translated"]["description"],
                    "distinctive_features": result["data"]["translated"]["distinctive_features"]
                }
            }
            return ko_result
        else:
            raise HTTPException(status_code=500, detail=result["error"])
            
    except Exception as e:
        # 예외 발생 시 임시 파일 삭제 시도
        try:
            if 'temp_path' in locals() and os.path.exists(temp_path):
                os.unlink(temp_path)
        except:
            pass
        
        raise HTTPException(status_code=500, detail=f"이미지 분석 중 오류 발생: {str(e)}")

# API 상태, 환경변수 확인
@app.get("/status")
async def status():

    global analyzer
    
    if not analyzer:
        return {"status": "error", "message": "분석기가 초기화되지 않았습니다."}
    
    return {
        "status": "ok",
        "papago_api": "active" if analyzer.translator.use_papago else "inactive",
        "models_loaded": True
    }


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))

    # 서버 실행
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=True)
