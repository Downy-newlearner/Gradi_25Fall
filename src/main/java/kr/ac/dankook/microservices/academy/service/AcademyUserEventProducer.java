package kr.ac.dankook.microservices.academy.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class AcademyUserEventProducer {

    private final KafkaTemplate<String, String> kafkaTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final String TOPIC = "academy-user-event";

    public void sendEvent(Object event) {
        try {
            String json = objectMapper.writeValueAsString(event); // 🔥 JSON String 변환
            kafkaTemplate.send(new ProducerRecord<>(TOPIC, json));

            log.info("📤 Kafka Event Published: {}", json);
        } catch (Exception e) {
            log.error("Kafka 메시지 직렬화 실패", e);
        }
    }
}
