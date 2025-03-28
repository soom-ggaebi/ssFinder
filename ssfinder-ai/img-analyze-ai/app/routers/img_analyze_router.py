import os
import tempfile
from fastapi import APIRouter, File, UploadFile, HTTPException, Depends
from typing import Dict, Any

# API 라우터 생성
router = APIRouter()

# 분석기 가져오기
def get_analyzer():
    from app.main import analyzer
    if not analyzer:
        raise HTTPException(status_code=500, detail="분석기가 초기화되지 않았습니다.")
    
    # 인스턴스 확인을 위한 로그 추가
    print(f"get_analyzer 호출됨: translator.use_papago={analyzer.translator.use_papago}")

    return analyzer

# API 루트 경로 핸들러
@router.get("/")
async def root():
    return {"message": "분실물 이미지 분석 API가 실행 중입니다."}

# 이미지 분석 후 정보 JSON으로 반환
@router.post("/analyze")
async def analyze_image(
    file: UploadFile = File(...),
    analyzer = Depends(get_analyzer)
):
    
    # 파일 확장자 검증
    valid_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.gif']
    file_ext = os.path.splitext(file.filename)[1].lower()
    
    if file_ext not in valid_extensions:
        raise HTTPException(
            status_code=400, 
            detail=f"지원되지 않는 파일 형식입니다. 지원되는 형식: {', '.join(valid_extensions)}"
        )
    
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
@router.get("/status")
async def status(analyzer = Depends(get_analyzer)):
    print(f"상태 확인: analyzer.translator.use_papago={analyzer.translator.use_papago}")
    return {
        "status": "ok",
        "papago_api": "active" if analyzer.translator.use_papago else "inactive",
        "models_loaded": True
    }
