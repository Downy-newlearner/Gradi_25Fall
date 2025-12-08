#!/usr/bin/env python3
"""
Kafka 토픽 모니터링 스크립트
grading-status와 student-answer 토픽의 메시지를 실시간으로 확인합니다.
"""

import asyncio
import json
from aiokafka import AIOKafkaConsumer

KAFKA_BOOTSTRAP_SERVERS = "3.34.214.133:9092"
TOPICS = ["grading-status", "student-answer"]


async def monitor_topics():
    """토픽 메시지 모니터링"""
    consumer = AIOKafkaConsumer(
        *TOPICS,
        bootstrap_servers=KAFKA_BOOTSTRAP_SERVERS,
        group_id="monitor-consumer",
        value_deserializer=lambda v: v.decode("utf-8"),
        auto_offset_reset="latest",
        enable_auto_commit=True
    )
    
    await consumer.start()
    print(f"✅ 모니터링 시작: {TOPICS}")
    print("=" * 60)
    
    try:
        async for msg in consumer:
            print(f"\n📨 토픽: {msg.topic}")
            print(f"   파티션: {msg.partition}, 오프셋: {msg.offset}")
            
            try:
                data = json.loads(msg.value)
                print(f"   메시지:")
                print(json.dumps(data, indent=4, ensure_ascii=False))
            except json.JSONDecodeError:
                print(f"   원본: {msg.value}")
            
            print("-" * 60)
            
    except asyncio.CancelledError:
        print("\n모니터링 종료")
    finally:
        await consumer.stop()


if __name__ == "__main__":
    try:
        asyncio.run(monitor_topics())
    except KeyboardInterrupt:
        print("\n종료됨")