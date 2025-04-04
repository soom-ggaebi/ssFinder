# 분실물 / 습득물 이미지 분석 AI

BLIP 모델을 활용해 분실물 이미지를 분석하고, 해당 물품의 특성(카테고리, 색상, 재질, 브랜드 등)을 자동으로 추출하는 AI

## 주요 기능

- 이미지 캡셔닝: 분실물 이미지에 대한 설명 생성
- 특징 추출: 물품의 카테고리, 색상, 재질, 브랜드, 특이사항 등 식별
- 한국어 번역: BLIP으로 추출된 영어 캡셔닝 특징 정보를 한국어로 번역 (파파고 API 활용)
- REST API: FastAPI 기반 인터페이스 제공

## 시스템 구성
- `main.py`: FastAPI 애플리케이션과 서버 설정
- `api/routers/img_analyze_router.py`: API 엔드포인트 정의
- `models/models.py`: 이미지 분석과 특징 추출을 위한 BLIP 모델 관련 기능
- `models/translator.py`: 파파고 API를 활용한 번역 서비스
- `config/config.py`: 설정 및 상수 정의 모듈

## 설치 및 실행 방법

### 준비 사항

- Python 3.8 이상
- [선택] 네이버 파파고 API 키 (한국어 번역 기능 사용 시)

### 환경 변수 설정

`.env` 파일을 프로젝트 루트 디렉토리에 생성하고 다음과 같이 설정:

```
NAVER_CLIENT_ID=your_naver_client_id
NAVER_CLIENT_SECRET=your_naver_client_secret
```

### 로컬 실행

1. 필요한 패키지 설치:
```bash
pip install -r requirements.txt
```

2. 서버 실행:
```bash
# 프로젝트 루트 디렉토리에서 실행
uvicorn main:app --reload --port 5001
```

또는

```bash
# 프로젝트 루트 디렉토리에서 실행
uvicorn main:app --host 0.0.0.0 --port 5001 --reload
```

3. 브라우저에서 `http://localhost:5001/docs`에 접속하여 API 문서 확인

### Docker를 이용한 실행

1. Docker 이미지 빌드:
```bash
docker build -t lost-item-analyzer -f docker/Dockerfile .
```

2. Docker 컨테이너 실행:
```bash
docker run -d -p 5001:5001 --env-file .env --name lost-item-api lost-item-analyzer
```

## API

### 이미지 분석 API

- URL: `POST /analyze`
- 설명: 이미지 파일을 업로드하여 분실물 분석 결과를 받습니다.
- Request: 
  - Content-Type: `multipart/form-data`
  - Body: `file` (이미지 파일)
- Response: 
  ```json
  {
    "status": "success",
    "data": {
      "title": "검정색 가방",
      "category": "가방",
      "color": "검정색",
      "material": "가죽",
      "brand": "루이비통",
      "description": "이 물건은 가죽 재질의 검정색 가방입니다.",
      "distinctive_features": "금색 지퍼와 숄더 스트랩이 있습니다."
    }
  }
  ```

### 상태 확인 API

- URL: `GET /status`
- 설명: API 서비스 상태 및 파파고 연결 상태를 확인합니다.
- Response:
  ```json
  {
    "status": "ok",
    "papago_api": "active",
    "models_loaded": true
  }
  ```

## AI 모델 정보

- [BLIP (Bootstrapping Language-Image Pre-training)](https://github.com/salesforce/BLIP) by Salesforce
  - `blip-image-captioning-large`: 이미지 캡셔닝 모델
  - `blip-vqa-capfilt-large`: 시각적 질의응답(VQA) 모델
