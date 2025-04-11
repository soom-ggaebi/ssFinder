import os
import sys
import logging
import torch
from transformers import CLIPProcessor, CLIPModel
from PIL import Image
import requests
from io import BytesIO
import numpy as np
import time


# 캐시 디렉토리 설정
os.environ['TRANSFORMERS_CACHE'] = '/tmp/huggingface_cache'
os.environ['HF_HOME'] = '/tmp/huggingface_cache'

# 디렉토리 생성
os.makedirs('/tmp/huggingface_cache', exist_ok=True)
os.makedirs('/tmp/uploads', exist_ok=True)

# 로깅 설정
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# 모델 설정 - 환경 변수에서 가져오거나 기본값 사용
CLIP_MODEL_NAME = os.getenv('CLIP_MODEL_NAME', 'Bingsu/clip-vit-large-patch14-ko')
DEVICE = "cuda" if torch.cuda.is_available() and os.getenv('USE_GPU', 'True').lower() == 'true' else "cpu"

# 요청 타임아웃 설정
REQUEST_TIMEOUT = int(os.getenv('REQUEST_TIMEOUT', '10'))  # 10초 타임아웃

def preload_clip_model():
    """CLIP 모델을 사전에 다운로드하고 캐시"""
    try:
        start_time = time.time()
        logger.info(f"CLIP 모델 사전 다운로드 시작: {CLIP_MODEL_NAME}")
        
        # 모델과 프로세서 사전 다운로드
        CLIPModel.from_pretrained(
            CLIP_MODEL_NAME, 
            cache_dir='/tmp/huggingface_cache',
            low_cpu_mem_usage=True,  # 메모리 사용 최적화
            torch_dtype=torch.float32  # float32 타입으로 통일
        )
        
        CLIPProcessor.from_pretrained(
            CLIP_MODEL_NAME, 
            cache_dir='/tmp/huggingface_cache'
        )
        
        logger.info(f"✅ CLIP 모델 사전 다운로드 완료 (소요시간: {time.time() - start_time:.2f}초)")
    except Exception as e:
        logger.error(f"❌ CLIP 모델 사전 다운로드 실패: {str(e)}")

class KoreanCLIPModel:
    
    def __init__(self, model_name=CLIP_MODEL_NAME, device=DEVICE):
        """CLIP 모델 초기화 - 메모리 최적화"""
        self.device = device
        self.model_name = model_name
        self.embedding_dim = None  # 추가: 임베딩 차원 저장
        
        logger.info(f"CLIP 모델 '{model_name}' 로드 중 (device: {device})...")
        
        try:
            # 캐시 디렉토리 설정
            os.environ["TRANSFORMERS_CACHE"] = "/tmp/transformers_cache"
            os.makedirs("/tmp/transformers_cache", exist_ok=True)
            
            # 메모리 최적화 옵션 추가 - float32 타입으로 통일
            self.model = CLIPModel.from_pretrained(
                model_name,
                cache_dir='/tmp/huggingface_cache',
                low_cpu_mem_usage=True,
                torch_dtype=torch.float32  # float16에서 float32로 변경
            ).to(device)
            
            # 임베딩 차원 저장
            self.text_embedding_dim = self.model.text_model.config.hidden_size
            self.image_embedding_dim = self.model.vision_model.config.hidden_size
            
            logger.info(f"텍스트 임베딩 차원: {self.text_embedding_dim}, 이미지 임베딩 차원: {self.image_embedding_dim}")
            
            self.processor = CLIPProcessor.from_pretrained(
                model_name,
                cache_dir='/tmp/huggingface_cache'
            )
            logger.info("CLIP 모델 로드 완료")
        except Exception as e:
            logger.error(f"CLIP 모델 로드 실패: {str(e)}")
            import traceback
            logger.error(traceback.format_exc())
            raise
            
    def encode_text(self, text):
        """
        텍스트를 임베딩 벡터로 변환
        """
        if isinstance(text, str):
            text = [text]
            
        try:
            with torch.no_grad():
                # 텍스트 인코딩
                inputs = self.processor(text=text, return_tensors="pt", padding=True, truncation=True).to(self.device)
                text_features = self.model.get_text_features(**inputs)
                
                # 텍스트 특성 정규화
                text_embeddings = text_features / text_features.norm(dim=1, keepdim=True)
                
            return text_embeddings.cpu().numpy()
        except Exception as e:
            logger.error(f"텍스트 인코딩 중 오류 발생: {str(e)}")
            # 차원이 일치하는 0 벡터 반환
            return np.zeros((len(text), self.text_embedding_dim))
            
    def encode_image(self, image_source):
        """
        이미지를 임베딩 벡터로 변환
        """
        try:
            # 이미지 로드 (URL, 파일 경로, PIL 이미지 객체 또는 Base64)
            if isinstance(image_source, str):
                if image_source.startswith('http'):
                    # URL에서 이미지 로드 - 타임아웃 추가
                    try:
                        response = requests.get(image_source, timeout=REQUEST_TIMEOUT)
                        if response.status_code == 200:
                            image = Image.open(BytesIO(response.content)).convert('RGB')
                        else:
                            logger.warning(f"이미지 URL에서 응답 오류: {response.status_code}")
                            # 오류 시 더미 이미지 생성 (검은색 이미지)
                            image = Image.new('RGB', (224, 224), color='black')
                    except requests.exceptions.RequestException as e:
                        logger.error(f"이미지 URL 접근 중 오류 발생: {str(e)}")
                        # 오류 시 더미 이미지 생성 (검은색 이미지)
                        image = Image.new('RGB', (224, 224), color='black')
                else:
                    # 로컬 파일에서 이미지 로드
                    try:
                        if os.path.exists(image_source):
                            image = Image.open(image_source).convert('RGB')
                        else:
                            logger.warning(f"이미지 파일이 존재하지 않음: {image_source}")
                            # 파일이 없는 경우 더미 이미지 생성
                            image = Image.new('RGB', (224, 224), color='black')
                    except Exception as e:
                        logger.error(f"로컬 이미지 로드 중 오류: {str(e)}")
                        # 오류 시 더미 이미지 생성
                        image = Image.new('RGB', (224, 224), color='black')
            else:
                # 이미 PIL 이미지 객체인 경우
                image = image_source.convert('RGB')
                
            with torch.no_grad():
                # 이미지 인코딩
                inputs = self.processor(images=image, return_tensors="pt").to(self.device)
                image_features = self.model.get_image_features(**inputs)
                
                # 이미지 특성 정규화
                image_embeddings = image_features / image_features.norm(dim=1, keepdim=True)
                
            return image_embeddings.cpu().numpy()
        except Exception as e:
            logger.error(f"이미지 인코딩 중 오류 발생: {str(e)}")
            # 차원이 일치하는 0 벡터 반환
            return np.zeros((1, self.image_embedding_dim))
    
    def calculate_similarity(self, embedding1, embedding2):
        """
        두 임베딩 간의 유사도 계산
        """
        try:
            # 차원 확인 및 로깅
            logger.debug(f"임베딩1 shape: {embedding1.shape}, 임베딩2 shape: {embedding2.shape}")
            
            # 차원이 다른 경우 예외 처리 - 차원이 맞지 않으면 기본값 반환
            if embedding1.shape[1] != embedding2.shape[1]:
                logger.warning(f"임베딩 차원 불일치: {embedding1.shape} vs {embedding2.shape}")
                return 0.5
                
            # 코사인 유사도 계산
            similarity = np.dot(embedding1, embedding2.T)[0, 0]
                
            # 유사도를 0~1 범위로 정규화
            similarity = (similarity + 1) / 2
            return float(similarity)
        except Exception as e:
            logger.error(f"유사도 계산 중 오류 발생: {str(e)}")
            return 0.5  # 오류 시 중간값 반환
        
    def encode_batch_texts(self, texts):
        """
        여러 텍스트를 한 번에 임베딩
        """
        # 배치 처리를 위한 코드
        # 메모리 크기에 따라 적절한 배치 크기 조정 필요
        return self.encode_text(texts)

# 모듈 테스트용 코드
if __name__ == "__main__":
    # 모델 초기화
    clip_model = KoreanCLIPModel()
    
    # 샘플 텍스트 인코딩
    sample_text = "검은색 지갑을 잃어버렸습니다. 현금과 카드가 들어있어요."
    text_embedding = clip_model.encode_text(sample_text)
    
    print(f"텍스트 임베딩 shape: {text_embedding.shape}")
    
    # 유사도 계산 (텍스트만)
    sample_text2 = "검은색 지갑을 찾았습니다. 안에 현금과 카드가 있습니다."
    text_embedding2 = clip_model.encode_text(sample_text2)
    
    similarity = clip_model.calculate_similarity(text_embedding, text_embedding2)
    print(f"텍스트 간 유사도: {similarity:.4f}")