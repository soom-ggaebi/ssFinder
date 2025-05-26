"""
데이터 파이프라인 실행 스크립트
명령줄에서 파이프라인을 실행하기 위한 엔트리 포인트입니다.
"""
import argparse
import logging
import os
import sys
from dotenv import load_dotenv

# 프로젝트 루트 디렉토리 추가
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# 환경 변수 로드
load_dotenv()

from core.pipeline import run_pipeline

def main():
    """파이프라인 실행 메인 함수"""
    parser = argparse.ArgumentParser(description='데이터 파이프라인 실행')
    parser.add_argument('--start-date', type=str, help='데이터 수집 시작일 (YYYYMMDD 형식)')
    parser.add_argument('--end-date', type=str, help='데이터 수집 종료일 (YYYYMMDD 형식)')
    parser.add_argument('--sequential', action='store_true', help='순차 실행 모드 (프로듀서 완료 후 다른 서비스 시작)')
    parser.add_argument('--log-level', type=str, default='INFO', 
                      choices=['DEBUG', 'INFO', 'WARNING', 'ERROR', 'CRITICAL'],
                      help='로깅 레벨 (기본값: INFO)')
    
    args = parser.parse_args()
    
    # 로깅 설정
    log_format = '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    logging.basicConfig(level=getattr(logging, args.log_level), format=log_format)
    
    # 파이프라인 실행
    run_pipeline(
        start_date=args.start_date,
        end_date=args.end_date,
        sequential_mode=args.sequential,
        register_signals=True  # 명령줄에서는 시그널 핸들러 등록
    )

if __name__ == '__main__':
    main()