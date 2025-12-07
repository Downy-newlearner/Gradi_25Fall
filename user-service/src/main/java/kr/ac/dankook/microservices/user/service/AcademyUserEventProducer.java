package kr.ac.dankook.microservices.user.service;

import kr.ac.dankook.microservices.common.dto.AcademyUserEvent;
import lombok.RequiredArgsConstructor;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.support.SendResult;
import org.springframework.stereotype.Service;


import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
public class AcademyUserEventProducer {


    private final KafkaTemplate<String, AcademyUserEvent> kafkaTemplate;

    public CompletableFuture<SendResult<String, AcademyUserEvent>> sendAcademyUserEvent(AcademyUserEvent event) {
        CompletableFuture<SendResult<String, AcademyUserEvent>> future = new CompletableFuture<>();

        // ListenableFuture.addCallback 대신 람다로 직접 처리
        kafkaTemplate.send("user-academy-events", event)
                .whenComplete((result, ex) -> {
                    if (ex != null) {
                        future.completeExceptionally(ex);
                    } else {
                        future.complete(result);
                    }
                });

        return future;
    }
}
