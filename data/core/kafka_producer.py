"""
Kafka 프로듀서 모듈
개별 및 배치 메시지 전송을 지원합니다.
"""
import json
import logging
from confluent_kafka import Producer
from config.config import KAFKA_BOOTSTRAP_SERVERS, KAFKA_BATCH_SIZE
from typing import Dict, List, Any, Optional, Union

logger = logging.getLogger(__name__)

# 프로듀서 인스턴스 캐싱
_producer_instance = None

def get_producer():
    """싱글톤 Kafka 프로듀서 인스턴스 반환"""
    global _producer_instance
    if _producer_instance is None:
        # 프로듀서 설정
        config = {
            'bootstrap.servers': KAFKA_BOOTSTRAP_SERVERS,
            'queue.buffering.max.messages': 100000,  # 내부 큐 크기
            'queue.buffering.max.ms': 100,  # 배치 처리 간격 (ms)
            'batch.size': 16384,  # 배치 메시지 크기 (bytes)
            'linger.ms': 5,  # 배치 지연 시간 (ms)
            'compression.type': 'snappy',  # 압축 사용
            'acks': '1'  # 확인 레벨 (0=확인 없음, 1=리더 확인, all=모든 복제본 확인)
        }
        _producer_instance = Producer(config)
    return _producer_instance

def delivery_report(err, msg):
    """Kafka 메시지 전송 결과 콜백 함수"""
    if err is not None:
        logger.error(f"메시지 전송 실패: {err}")
    else:
        logger.debug(f"메시지 전송 성공: {msg.topic()} [{msg.partition()}] at offset {msg.offset()}")

def send_to_kafka(topic: str, message: Dict[str, Any], key: Optional[str] = None):
    """
    단일 메시지를 Kafka 토픽에 전송
    
    Args:
        topic: 대상 Kafka 토픽
        message: 전송할 메시지 (dict)
        key: 메시지 키 (선택 사항)
    """
    producer = get_producer()
    
    # 메시지 직렬화
    value = json.dumps(message, ensure_ascii=False, default=str).encode('utf-8')
    
    # 키가 제공된 경우 인코딩
    key_bytes = key.encode('utf-8') if key else None
    
    # 메시지 전송
    producer.produce(
        topic=topic,
        value=value,
        key=key_bytes,
        callback=delivery_report
    )
    
    # 즉시 전송을 위한 flush는 필요 없음 (배치 처리 사용)
    # 주기적으로 poll 호출하여 전송 상태 확인
    producer.poll(0)

def send_batch_to_kafka(topic: str, messages: List[Dict[str, Any]]):
    """
    메시지 배치를 Kafka 토픽에 전송
    
    Args:
        topic: 대상 Kafka 토픽
        messages: 전송할 메시지 리스트, 각 항목은 {"key": key, "value": value} 형식
    """
    if not messages:
        return
        
    producer = get_producer()
    
    # 배치 단위로 메시지 전송
    for message in messages:
        value = message.get("value")
        key = message.get("key")
        
        if value:
            # 메시지 직렬화
            value_bytes = json.dumps(value, ensure_ascii=False, default=str).encode('utf-8')
            
            # 키가 제공된 경우 인코딩
            key_bytes = key.encode('utf-8') if key else None
            
            # 메시지 전송 (비동기)
            producer.produce(
                topic=topic,
                value=value_bytes,
                key=key_bytes,
                callback=delivery_report
            )
            
        # 주기적으로 poll 호출하여 콜백 처리
        producer.poll(0)
    
    # 모든 메시지가 큐에 들어간 후 flush
    producer.flush()
    logger.info(f"{len(messages)}개 메시지를 {topic} 토픽에 전송 완료")

def flush_producer():
    """프로듀서 내부 큐의 모든 메시지를 즉시 전송"""
    if _producer_instance:
        _producer_instance.flush()