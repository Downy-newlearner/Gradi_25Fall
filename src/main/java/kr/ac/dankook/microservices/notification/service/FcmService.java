package kr.ac.dankook.microservices.notification.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.google.api.core.ApiFuture;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.Message;
import com.google.firebase.messaging.Notification;
import kr.ac.dankook.microservices.notification.dto.FcmRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.Executors;

@Service
public class FcmService {

    private final FcmTokenCacheService tokenCacheService;
    @Autowired
    private ObjectMapper objectMapper;
    public FcmService(FcmTokenCacheService tokenCacheService) {
        this.tokenCacheService = tokenCacheService;
    }

    /**
     * 사용자별 FCM 토큰 등록 (Redis 저장)
     */
    public void activateToken(FcmRequest fcmRequest) {
        if (fcmRequest.getUser_id() == null || fcmRequest.getToken() == null) {
            throw new IllegalArgumentException("userId와 token은 필수입니다.");
        }
        tokenCacheService.saveToken(fcmRequest.getUser_id(), fcmRequest.getToken());
    }

    /**
     * 특정 사용자에게 푸시 알림 전송
     */
    public void sendToUser(FcmRequest fcmRequest) {
        String token = tokenCacheService.getToken(fcmRequest.getUser_id());
        if (token == null) {
            System.err.println("❌ Redis에 사용자 " + fcmRequest.getUser_id() + "의 FCM 토큰이 없습니다.");
            return;
        }

        Message message = Message.builder()
                .setToken(token)
                .setNotification(Notification.builder()
                        .setTitle(fcmRequest.getTitle())
                        .setBody(fcmRequest.getBody())
                        .build())
                .build();

        ApiFuture<String> future = FirebaseMessaging.getInstance().sendAsync(message);
        future.addListener(() -> {
            try {
                String messageId = future.get();
                System.out.println("✅ 푸시 전송 성공 (userId=" + fcmRequest.getUser_id() + ", messageId=" + messageId + ")");
            } catch (Exception e) {
                System.err.println("❌ 푸시 전송 실패 (userId=" + fcmRequest.getUser_id() + ")");
                e.printStackTrace();
            }
        }, Executors.newSingleThreadExecutor());
    }


    public <T> void sendGeneric(FcmRequest<T> req) {
        String token = tokenCacheService.getToken(req.getUser_id());
        if (token == null) {
            System.err.println("❌ Redis에 토큰 없음 userId=" + req.getUser_id());
            return;
        }

        Message.Builder msgBuilder = Message.builder()
                .setToken(token)
                .setNotification(Notification.builder()
                        .setTitle(req.getTitle())
                        .setBody(req.getBody())
                        .build());

        if (req.getData() != null) {

            Map<String, Object> dataMap = objectMapper.convertValue(
                    req.getData(),
                    new TypeReference<Map<String, Object>>() {}
            );

            dataMap.forEach((key, value) -> {
                msgBuilder.putData(key, value == null ? "" : value.toString());
            });
        }


        Message message = msgBuilder.build();

        FirebaseMessaging.getInstance().sendAsync(message);
    }

}
