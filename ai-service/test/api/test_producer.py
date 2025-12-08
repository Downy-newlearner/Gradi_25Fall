#!/usr/bin/env python3
"""
테스트용 Kafka 메시지 발송 스크립트
s3-download-url 토픽으로 테스트 메시지를 전송합니다.
"""

import asyncio
import json
from aiokafka import AIOKafkaProducer

KAFKA_BOOTSTRAP_SERVERS = "3.34.214.133:9092"
TOPIC = "s3-download-url"


async def send_test_message():
    """테스트 메시지 전송"""
    producer = AIOKafkaProducer(
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS
    )
    
    await producer.start()
    
    try:
        # 테스트 메시지
        message = {
            "downloadUrl": "https://example.com/test-image.jpg",
            "uploadUrl": "https://example-bucket.s3.amazonaws.com/uploads",
            "academy_user_id": 1,
            "user_id": 100,
            "class_id": 10,
            "academy_id": 1,
            "student_response_id": 12345,
            "index": 1,
            "total": 1
        }
        
        await producer.send_and_wait(
            TOPIC,
            value=json.dumps(message).encode('utf-8')
        )
        
        print(f"✅ 테스트 메시지 전송 완료")
        print(f"   토픽: {TOPIC}")
        print(f"   메시지: {json.dumps(message, indent=2)}")
        
    finally:
        await producer.stop()


if __name__ == "__main__":
    asyncio.run(send_test_message())