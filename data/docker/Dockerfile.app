# docker/Dockerfile.app
FROM python:3.9-slim-buster

# 패키지 업데이트 및 Java 11 설치, procps 설치
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk procps && \
    rm -rf /var/lib/apt/lists/*

# JAVA_HOME 환경변수 설정 (Debian Bullseye의 경우 OpenJDK 11 경로)
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

WORKDIR /data

COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt

COPY . /data/

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
