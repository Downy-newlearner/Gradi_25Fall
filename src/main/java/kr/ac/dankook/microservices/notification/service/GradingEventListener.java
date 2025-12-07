package kr.ac.dankook.microservices.notification.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.ac.dankook.microservices.common.dto.GradingEvent;
import kr.ac.dankook.microservices.notification.dto.FcmRequest;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;


@Slf4j
@Service
@RequiredArgsConstructor
public class GradingEventListener {

    private final ObjectMapper objectMapper;

    private final FcmService fcmService;
    private final WebClientService webClientService;


    @KafkaListener(topics = "grading-event")
    public void receiveGradingEvent(String message) {
        try {
            if (message == null || message.isBlank()) {
                log.warn("Empty grading-event message received, skipping");
                return;
            }

            GradingEvent event;
            try {
                event = objectMapper.readValue(message, GradingEvent.class);
            } catch (Exception e) {
                if (message.matches("\\d+")) {
                    event = new GradingEvent();
                    event.setStudentResponseId(Long.valueOf(message));
                    log.warn("Received numeric-only grading-event, created partial object: {}", event);
                } else {
                    throw e;
                }
            }

            String action = event.getAction();

            if (!"GRADING_STARTED".equals(action) && !"GRADING_ENDED".equals(action)) {
                log.warn("Unsupported grading-event action: {}", action);
                return;
            }

            // ==============================
            // WebClient 조회
            // ==============================
            String academyName = parseJsonField(
                    webClientService.academySafeGet("/{id}", event.getAcademyId()),
                    "academyName"
            );

            String className = null;

            // ⭐ class_id == 0 이면 조회하지 않음
            if (event.getClassId() != null && event.getClassId() != 0) {
                className = parseJsonField(
                        webClientService.academySafeGet("/class/{id}", event.getClassId()),
                        "className"
                );
            }

            String bookName = parseJsonField(
                    webClientService.gradingSafeGet("/book/{id}", event.getBookId()),
                    "book_name"
            );

            // ==============================
            // FCM 메시지 생성
            // ==============================
            String title;
            String body;

            // 학원명 + (class가 있으면 함께 표시)
            String prefix = (className != null)
                    ? String.format("[%s - %s]", academyName, className)
                    : String.format("[%s]", academyName);

            if ("GRADING_STARTED".equals(action)) {
                title = "채점 시작 알림";
                body = String.format("%s %s 교재의 채점이 시작되었습니다.", prefix, bookName);
            } else {
                title = "채점 완료 알림";
                body = String.format("%s %s 교재의 채점이 완료되었습니다.", prefix, bookName);
            }

            // ==============================
            // FCM 전송
            // ==============================
            FcmRequest<GradingEvent> request = new FcmRequest<>();
            request.setUser_id(event.getUserId());
            request.setTitle(title);
            request.setBody(body);
            request.setData(event);

            fcmService.sendGeneric(request);

            log.info("📢 Push notification sent: [{}] {}", action, request);

        } catch (Exception e) {
            log.error("❌ Failed to process grading-event message: {}", message, e);
        }
    }


    // ==============================
    // JSON 안전 필드 추출
    // ==============================
    private String parseJsonField(String json, String field) {
        try {
            JsonNode node = objectMapper.readTree(json);

            // Case 1: 배열인 경우 → 첫 번째 element에서 찾기
            if (node.isArray() && node.size() > 0) {
                JsonNode first = node.get(0);
                if (first.has(field)) {
                    return first.get(field).asText();
                }
            }

            // Case 2: 객체인 경우
            if (node.isObject() && node.has(field)) {
                return node.get(field).asText();
            }

            log.warn("Field '{}' not found in JSON: {}", field, json);
            return "(정보 없음)";

        } catch (Exception e) {
            log.warn("Failed to parse JSON: {}", json, e);
            return "(정보 없음)";
        }
    }




}

