//package kr.ac.dankook.microservices.storage.service;
//
//import kr.ac.dankook.microservices.storage.dto.FileRequestDto;
//import lombok.RequiredArgsConstructor;
//import org.springframework.beans.factory.annotation.Value;
//import org.springframework.kafka.core.KafkaTemplate;
//import org.springframework.stereotype.Service;
//
//@Service
//@RequiredArgsConstructor
//public class KafkaProducerService {
//
//    private final S3Service s3Service;
//    private final KafkaTemplate<String, String> kafkaTemplate;
//
//    @Value("${kafka.topic.download}")
//    private String downloadTopic;
//
//    public void sendDownloadUrl(FileRequestDto requestDto) {
//        String url = s3Service.getDownloadUrl(requestDto);
//
//        // JSON 형태로 메시지 생성
//        String message = String.format(
//                "{\"academy\":\"%s\", \"clazz\":\"%s\", \"assessment_id\":\"%s\", \"file_name\":\"%s\", \"url\":\"%s\"}",
//                requestDto.getAcademy(),
//                requestDto.getClazz(),
//                requestDto.getAssessment_id(),
//                requestDto.getFile_name(),
//                url
//        );
//
//        kafkaTemplate.send(downloadTopic, message);
//    }
//}
