package kr.ac.dankook.microservices.notification.service;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
public class FcmTokenCacheService {

    private final StringRedisTemplate redisTemplate;
    private static final long TOKEN_TTL = 7 * 24 * 60 * 60; // 7일 (초 단위)

    public FcmTokenCacheService(StringRedisTemplate redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    // FCM 토큰 저장
    public void saveToken(Long userId, String token) {
        String key = "fcm:" + userId;
        redisTemplate.opsForValue().set(key, token, TOKEN_TTL, TimeUnit.SECONDS);
        System.out.println("💾 Redis에 FCM 토큰 저장: " + key + " → " + token);
    }

    // FCM 토큰 조회
    public String getToken(Long userId) {
        return redisTemplate.opsForValue().get("fcm:" + userId);
    }

    // 토큰 삭제 (로그아웃 시)
    public void deleteToken(Long userId) {
        redisTemplate.delete("fcm:" + userId);
        System.out.println("🧹 Redis에서 FCM 토큰 삭제: fcm:" + userId);
    }
}
