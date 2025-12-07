package kr.ac.dankook.microservices.notification.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.ac.dankook.microservices.common.dto.AcademyUserEvent;
import kr.ac.dankook.microservices.notification.dto.FcmRequest;
import kr.ac.dankook.microservices.notification.service.FcmService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class AcademyUserEventListener {

    private final FcmService fcmService;

    @KafkaListener(topics = "academy-user-event")
    public void handleAcademyUserEvent(String jsonEvent) throws JsonProcessingException {
        System.out.println("▶ KafkaListener invoked with raw JSON: " + jsonEvent);
        log.info("▶ KafkaListener invoked with raw JSON: {}", jsonEvent);

        ObjectMapper objectMapper = new ObjectMapper();
        AcademyUserEvent event;
        try {
            event = objectMapper.readValue(jsonEvent, AcademyUserEvent.class);
            System.out.println("▶ Converted to DTO: " + event);
            log.info("▶ Converted to DTO: {}", event);
        } catch (Exception e) {
            System.err.println("❌ Failed to convert JSON to DTO: " + e.getMessage());
            log.error("❌ Failed to convert JSON to DTO", e);
            return;
        }

        String title;
        String body;

        switch (event.getAction()) {
            case "JOIN_REQUEST":
                title = "📨 학원 가입 요청 완료";
                body = String.format("[%s] 학원에 가입 요청이 접수되었습니다.", event.getAcademy_name());
                break;
            case "JOIN_APPROVED":
                title = "✅ 학원 가입 승인";
                body = String.format("[%s] 학원 가입이 승인되었습니다.", event.getAcademy_name());
                break;
            case "LEAVE":
                title = "👋 학원 탈퇴 완료";
                body = String.format("[%s] 학원에서 탈퇴하셨습니다.", event.getAcademy_name());
                break;
            default:
                System.out.println("⚠️ Unknown action type: " + event.getAction());
                log.warn("⚠️ Unknown action type: {}", event.getAction());
                return;
        }

        System.out.println("▶ Preparing FCM request with title: " + title + ", body: " + body);
        log.info("▶ Preparing FCM request with title: {}, body: {}", title, body);

        FcmRequest fcmRequest = new FcmRequest();
        fcmRequest.setUser_id(event.getUser_id());
        fcmRequest.setTitle(title);
        fcmRequest.setBody(body);

        try {
            fcmService.sendToUser(fcmRequest);
            System.out.println("▶ FCM sent successfully to user: " + event.getUser_id());
            log.info("▶ FCM sent successfully to user: {}", event.getUser_id());
        } catch (Exception e) {
            System.err.println("❌ FCM sending failed: " + e.getMessage());
            log.error("❌ FCM sending failed", e);
        }
    }
}
