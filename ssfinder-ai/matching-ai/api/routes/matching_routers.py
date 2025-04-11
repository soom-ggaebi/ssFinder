import os
import sys
import logging
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Body
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field, validator
import base64
from io import BytesIO
from PIL import Image

# 로깅 설정
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 라우터 생성
router = APIRouter(
    prefix="/api/matching",
    tags=["matching"],
    responses={404: {"description": "Not found"}},
)

# Pydantic 모델 정의
class LostItemPost(BaseModel):
    """사용자가 분실한 물품 게시글 모델"""
    category: str = Field(..., description="분실물 카테고리 (예: 지갑, 가방, 전자기기)")
    item_name: str = Field(..., description="물품명 (예: 검은색 가죽 지갑)")
    color: Optional[str] = Field(None, description="물품 색상")
    content: str = Field(..., description="게시글 내용")
    location: Optional[str] = Field(None, description="분실 장소")
    image_url: Optional[str] = Field(None, description="이미지 URL (있는 경우)")
    lost_items: Optional[List[Dict[str, Any]]] = Field(None, description="비교할 습득물 데이터 (API 테스트용)")
    
    class Config:
        schema_extra = {
            "example": {
                "category": "지갑",
                "item_name": "검은색 가죽 지갑",
                "color": "검정색",
                "content": "지난주 토요일 강남역 근처에서 검정색 가죽 지갑을 잃어버렸습니다. 현금과 카드가 들어있어요.",
                "location": "강남역",
                "image_url": None
            }
        }

class ImageMatchingRequest(BaseModel):
    """이미지 기반 매칭 요청 모델"""
    category: Optional[str] = Field(None, description="분실물 카테고리")
    item_name: Optional[str] = Field(None, description="물품명")
    color: Optional[str] = Field(None, description="색상")
    content: Optional[str] = Field(None, description="내용")
    image_base64: Optional[str] = Field(None, description="Base64 인코딩된 이미지")
    lost_items: Optional[List[Dict[str, Any]]] = Field(None, description="비교할 습득물 데이터 (API 테스트용)")
    
    class Config:
        schema_extra = {
            "example": {
                "category": "지갑",
                "item_name": "검은색 가죽 지갑",
                "color": "검정색",
                "content": "지난주 토요일 강남역 근처에서 검정색 가죽 지갑을 잃어버렸습니다.",
                "image_base64": "[base64 encoded image string]"
            }
        }

class MatchingResult(BaseModel):
    """매칭 결과 모델"""
    total_matches: int = Field(..., description="매칭된 항목 수")
    similarity_threshold: float = Field(..., description="유사도 임계값")
    matches: List[Dict[str, Any]] = Field(..., description="매칭된 항목 목록")

class MatchingResponse(BaseModel):
    """API 응답 모델"""
    success: bool = Field(..., description="요청 성공 여부")
    message: str = Field(..., description="응답 메시지")
    result: Optional[MatchingResult] = Field(None, description="매칭 결과")