package kr.ac.dankook.microservices.grading.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import kr.ac.dankook.microservices.common.dto.GradingEvent;
import kr.ac.dankook.microservices.common.dto.StudentAnswerMessage;
import kr.ac.dankook.microservices.grading.mapper.StudentAnswerMapper;
import kr.ac.dankook.microservices.grading.entity.StudentAnswer;
import kr.ac.dankook.microservices.grading.repository.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Service;
import org.springframework.data.redis.core.RedisTemplate;
import kr.ac.dankook.microservices.common.dto.AnswerExplanationMessage;
import kr.ac.dankook.microservices.common.dto.ExplanationEvent;
import kr.ac.dankook.microservices.grading.entity.Book;

import java.util.List;

@Service
@Slf4j
@RequiredArgsConstructor
public class KafkaStudentResponseListener {

    private final ObjectMapper objectMapper;
    private final KafkaTemplate<String, String> kafkaTemplate;
    private final StudentResponseRepository studentResponseRepository;
    private final BookRepository bookRepository;
    private final AssessmentRepository assessmentRepository;
    private final GradingHistoryRepository gradingHistoryRepository;
    private final RedisTemplate<String, String> redisTemplate;
    private final StudentAnswerRepository studentAnswerRepository;
    private final GradingEndService gradingEndService;

    // ================================
    // grading-start
    // ================================
    @KafkaListener(topics = "grading-start", groupId = "grading-group")
    public void listenGradingStart(String message) {
        try {
            GradingEvent event = objectMapper.readValue(message, GradingEvent.class);
            if (!"GRADING_STARTED".equals(event.getAction())) return;

            studentResponseRepository.findById(event.getStudentResponseId())
                    .ifPresent(sr -> {
                        Book book = bookRepository.findById(event.getBookId()).orElse(null);
                        sr.setBook(book);
                        sr.setAcademyUserId(event.getAcademyUserId());
                        sr.setUnrecognizedResponseCount(event.getUnrecognizedResponseCount());
                        studentResponseRepository.save(sr);
                    });

            kafkaTemplate.send("grading-event", objectMapper.writeValueAsString(event));
        } catch (Exception e) {
            log.error("Failed to process grading-start message: {}", message, e);
        }
    }

    // ================================
    // grading-end
    // ================================
    @KafkaListener(topics = "grading-end", groupId = "grading-group")
    public void listenGradingEnd(String message) {
        try {
            GradingEvent event = objectMapper.readValue(message, GradingEvent.class);
            if (!"GRADING_ENDED".equals(event.getAction())) return;

            gradingEndService.process(event, message);

        } catch (Exception e) {
            log.error("Failed processing message: {}", message, e);
        }
    }

    // ================================
    // student-answer
    // ================================
    @KafkaListener(topics = "student-answer", groupId = "answer-group")
    public void listenStudentAnswer(String message) {
        try {
            StudentAnswerMessage dto = objectMapper.readValue(message, StudentAnswerMessage.class);
            List<StudentAnswer> entities = StudentAnswerMapper.toEntities(dto);
            studentAnswerRepository.saveAll(entities);
            log.info("Saved student_answer count: {}", entities.size());
        } catch (Exception e) {
            log.error("Failed to process student-answer message: {}", message, e);
        }
    }

    // ================================
    // answer-explanation
    // ================================
    @KafkaListener(topics = "answer-explanation", groupId = "grading-group")
    public void listenAnswerExplanation(String message) {
        try {
            AnswerExplanationMessage dto = objectMapper.readValue(message, AnswerExplanationMessage.class);

            // Redis 저장
            String key = String.format(
                    "answer-explanation:%d:%d:%d:%d",
                    dto.getStudentResponseId(),
                    dto.getAcademyUserId(),
                    dto.getQuestionNumber(),
                    dto.getSubQuestionNumber()
            );
            redisTemplate.opsForValue().set(key, objectMapper.writeValueAsString(dto));

            // ExplanationEvent 발행
            ExplanationEvent event = new ExplanationEvent();
            event.setStudentResponseId(dto.getStudentResponseId());
            event.setAcademyUserId(dto.getAcademyUserId());
            event.setQuestionNumber(dto.getQuestionNumber());
            event.setSubQuestionNumber(dto.getSubQuestionNumber());
            event.setUserId(dto.getUserId());
            event.setBookId(dto.getBookId());
            event.setChapterId(dto.getChapterId());
            event.setCorrect(dto.isCorrect());
            event.setScore(dto.getScore());

            kafkaTemplate.send("explanation-event", objectMapper.writeValueAsString(event));

        } catch (Exception e) {
            log.error("Failed to process answer-explanation message: {}", message, e);
        }
    }
}
