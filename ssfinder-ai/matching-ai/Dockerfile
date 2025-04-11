FROM python:3.9

# 캐시 디렉토리 환경변수 설정
ENV TRANSFORMERS_CACHE=/tmp/huggingface_cache
ENV HF_HOME=/tmp/huggingface_cache
ENV TORCH_HOME=/tmp/torch_cache
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 시스템 패키지 설치
RUN apt-get update && apt-get install -y \
    build-essential \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# 캐시 디렉토리 생성 및 권한 설정
RUN mkdir -p $TRANSFORMERS_CACHE && chmod -R 777 $TRANSFORMERS_CACHE
RUN mkdir -p $TORCH_HOME && chmod -R 777 $TORCH_HOME

# 임시 디렉토리 권한 설정
RUN mkdir -p /tmp/uploads && chmod 777 /tmp/uploads
ENV TMPDIR=/tmp/uploads

# 요구사항 파일 복사 및 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 애플리케이션 파일 복사
COPY . .

# 환경 변수 설정
ENV PYTHONPATH=/app
ENV HF_HUB_DISABLE_TELEMETRY=1
ENV TRANSFORMERS_VERBOSITY=error

EXPOSE 7860
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]