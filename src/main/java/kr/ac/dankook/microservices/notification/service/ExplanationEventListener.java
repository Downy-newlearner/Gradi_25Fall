package kr.ac.dankook.microservices.notification.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import kr.ac.dankook.microservices.common.dto.ExplanationEvent;
import kr.ac.dankook.microservices.notification.dto.FcmRequest;
import kr.ac.dankook.microservices.notification.dto.StudentResponseWithQuestionData;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class ExplanationEventListener {

    private final ObjectMapper objectMapper;
    private final FcmService fcmService;
    private final WebClientService webClientService;

    @KafkaListener(topics = "explanation-event")
    public void listenExplanationEvent(String message) {
        try {
            ExplanationEvent event = objectMapper.readValue(message, ExplanationEvent.class);

            log.info(
                    "ExplanationEvent received: studentResponseId={}, academyUserId={}, questionNumber={}, userId={}, bookId={}, chapterId={}",
                    event.getStudentResponseId(),
                    event.getAcademyUserId(),
                    event.getQuestionNumber(),
                    event.getUserId(),
                    event.getBookId(),
                    event.getChapterId()
            );

            if (event.getAcademyUserId() == null) {
                log.error("academyUserId is null. Event cannot be processed: {}", event);
                return;
            }

            // ==============================
            // WebClientService 안전 호출 + JSON 파싱
            // ==============================
            String className = parseJsonField(
                    webClientService.academySafeGet("/academy-users/classes?ids={id}", event.getAcademyUserId()),
                    "className"
            );

            String bookName = parseJsonField(
                    webClientService.gradingSafeGet("/book/{id}", event.getBookId()),
                    "book_name"
            );

            // ==============================
            // 메시지 생성
            // ==============================
            String title = "해설 생성 완료";
            String body  = String.format("[%s] 수업의 [%s] %d번 문제 해설 생성 완료",
                    className, bookName, event.getQuestionNumber()
            );

            // ==============================
            // FCM 전송 (payload = Kafka 메시지 전체)
            // ==============================
            FcmRequest<ExplanationEvent> req = new FcmRequest<>();
            req.setUser_id(event.getUserId());
            req.setTitle(title);
            req.setBody(body);
            req.setData(event);  // payload = Kafka 메시지 전체

            fcmService.sendGeneric(req);
            log.info("Push notification sent to userId={}", event.getUserId());

        } catch (Exception e) {
            log.error("Failed to process explanation-event message: {}", message, e);
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
