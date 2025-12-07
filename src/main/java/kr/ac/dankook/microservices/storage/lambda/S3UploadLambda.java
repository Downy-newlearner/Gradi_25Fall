package kr.ac.dankook.microservices.storage.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;
import kr.ac.dankook.microservices.storage.service.S3Service;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class S3UploadLambda implements RequestHandler<S3EventNotification, String> {

    @Autowired
    private StringRedisTemplate redisTemplate;

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @Autowired
    private S3Service s3Service;

    @Override
    public String handleRequest(S3EventNotification s3Event, Context context) {
        s3Event.getRecords().forEach(record -> {
            String key = record.getS3().getObject().getKey();
            System.out.println(key);
            // Redis에서 다운로드 URL 가져오기
            String downloadUrl = redisTemplate.opsForValue().get(key);

            if (downloadUrl != null) {
                log.info("Redis에서 다운로드 URL 조회 성공: key={}, downloadUrl={}", key, downloadUrl);

                // Kafka로 이벤트 발행
                kafkaTemplate.send("s3-download-url", downloadUrl);
            } else {
                log.warn("Redis에 다운로드 URL이 없음: key={}", key);
            }
        });
        return "success";
    }

}
