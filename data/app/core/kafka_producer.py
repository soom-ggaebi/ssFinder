import json
from confluent_kafka import Producer
from config.config import KAFKA_BROKER, KAFKA_TOPIC

def delivery_report(err, msg):
    if err is not None:
        print(f"Message delivery failed: {err}")
    else:
        print(f"Message delivered to {msg.topic()} [{msg.partition()}]")

def send_to_kafka(message):
    p = Producer({'bootstrap.servers': KAFKA_BROKER})
    p.produce(KAFKA_TOPIC, json.dumps(message, ensure_ascii=False, default=str).encode('utf-8'), callback=delivery_report)
    p.flush()
