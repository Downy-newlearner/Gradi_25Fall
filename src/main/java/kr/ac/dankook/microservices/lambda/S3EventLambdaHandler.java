package kr.ac.dankook.microservices.lambda;

import com.amazonaws.services.lambda.runtime.Context;
import com.amazonaws.services.lambda.runtime.RequestHandler;
import com.amazonaws.services.lambda.runtime.events.models.s3.S3EventNotification;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.clients.producer.RecordMetadata;

import redis.clients.jedis.Jedis;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Properties;
import java.util.concurrent.TimeUnit;

import org.json.JSONObject;

import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;

public class S3EventLambdaHandler implements RequestHandler<S3EventNotification, String> {

    private final KafkaProducer<String, String> producer;
    private final Jedis redisClient;
    private final S3Presigner presigner;

    private final String bucketName;
    private final int presignExpireMin;

    public S3EventLambdaHandler() {

        // ✅ Kafka (환경변수)
        Properties props = new Properties();
        props.put("bootstrap.servers", System.getenv("KAFKA_BOOTSTRAP_SERVERS"));
        props.put("key.serializer", "org.apache.kafka.common.serialization.StringSerializer");
        props.put("value.serializer", "org.apache.kafka.common.serialization.StringSerializer");

        producer = new KafkaProducer<>(props);
        System.out.println("[Init] Kafka producer initialized");

        // ✅ Redis (환경변수)
        String redisHost = System.getenv("REDIS_HOST");
        int redisPort = Integer.parseInt(System.getenv("REDIS_PORT"));
        String redisPassword = System.getenv("REDIS_PASSWORD");

        redisClient = new Jedis(redisHost, redisPort);
        redisClient.auth(redisPassword);

        System.out.println("[Init] Redis client initialized");

        // ✅ S3 Presigner
        presigner = S3Presigner.builder().build();
        System.out.println("[Init] S3 presigner initialized");

        // ✅ S3 설정 (환경변수)
        bucketName = System.getenv("S3_BUCKET_NAME");
        presignExpireMin = Integer.parseInt(System.getenv().getOrDefault("PRESIGNED_EXPIRE_MIN", "10"));
    }

    @Override
    public String handleRequest(S3EventNotification event, Context context) {

        try {
            for (S3EventNotification.S3EventNotificationRecord record : event.getRecords()) {

                String key = URLDecoder.decode(record.getS3().getObject().getKey(), StandardCharsets.UTF_8);
                System.out.println("[S3] Uploaded file detected: " + key);

                if (!key.startsWith("files/")) {
                    continue;
                }

                String[] parts = key.split("/");
                if (parts.length < 9) continue;

                Long academyId = Long.parseLong(parts[1]);
                Long classId = Long.parseLong(parts[2]);
                Long userId = Long.parseLong(parts[3]);
                Long academyUserId = Long.parseLong(parts[4]);
                Long studentResponseId = Long.parseLong(parts[5]);
                int total = Integer.parseInt(parts[6]);
                int index = Integer.parseInt(parts[7]);
                String fileName = parts[8];

                String fullKey = String.join("/", parts);

                String downloadUrl = generatePresignedGetUrl(fullKey);

                String redisKey = String.format("download:%d:%d:%d", studentResponseId, total, index);

                JSONObject json = new JSONObject();
                json.put("academy_id", academyId);
                json.put("class_id", classId);
                json.put("user_id", userId);
                json.put("academy_user_id", academyUserId);
                json.put("student_response_id", studentResponseId);
                json.put("file_name", fileName);
                json.put("download_url", downloadUrl);
                json.put("index", index);
                json.put("total", total);

                redisClient.set(redisKey, json.toString());
                redisClient.expire(redisKey, 600);

                ProducerRecord<String, String> recordKafka =
                        new ProducerRecord<>("s3-download-url", json.toString());

                producer.send(recordKafka).get(10, TimeUnit.SECONDS);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }

        return "success";
    }

    // ✅ Presigned URL도 env 기반으로 변경
    private String generatePresignedGetUrl(String key) {
        try {
            GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                    .bucket(bucketName)
                    .key(key)
                    .build();

            GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                    .signatureDuration(Duration.ofMinutes(presignExpireMin))
                    .getObjectRequest(getObjectRequest)
                    .build();

            PresignedGetObjectRequest presigned = presigner.presignGetObject(presignRequest);
            return presigned.url().toString();

        } catch (Exception e) {
            return "";
        }
    }
}
