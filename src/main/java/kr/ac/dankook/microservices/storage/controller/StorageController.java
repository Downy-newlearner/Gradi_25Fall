package kr.ac.dankook.microservices.storage.controller;

import kr.ac.dankook.microservices.storage.dto.FileRequestDto;
import kr.ac.dankook.microservices.storage.dto.UploadBatchResponseDto;
import kr.ac.dankook.microservices.storage.service.GradingServiceClient;
import kr.ac.dankook.microservices.storage.service.S3Service;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.codec.ServerSentEvent;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Sinks;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sts.StsClient;
import software.amazon.awssdk.services.sts.model.AssumeRoleRequest;
import software.amazon.awssdk.services.sts.model.AssumeRoleResponse;
import software.amazon.awssdk.services.sts.model.Credentials;

import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequiredArgsConstructor
@Slf4j
public class StorageController {

    private final S3Service s3Service;
    private final GradingServiceClient gradingServiceClient;   // WebClientConfig에서 등록한 Bean
    // SSE sink (멀티캐스트)
    private final Sinks.Many<ServerSentEvent<String>> sink = Sinks.many().multicast().onBackpressureBuffer();

    @Value("${aws.sts.account-id}")
    private String awsAccountId;

    @Value("${aws.sts.role-name}")
    private String roleName;

    @Value("${aws.sts.region}")
    private String region;

    @Value("${aws.credentials.access-key}")
    private String accessKey;

    @Value("${aws.credentials.secret-key}")
    private String secretKey;


    /** SSE 구독 엔드포인트 */
    @GetMapping(path = "/upload-stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public Flux<ServerSentEvent<String>> subscribeUploadStream() {
        return sink.asFlux()
                .mergeWith(Flux.interval(Duration.ofSeconds(15))
                        .map(t -> ServerSentEvent.builder("ping").event("ping").build()));
    }

    @PostMapping("/upload-url/batch")
    public UploadBatchResponseDto generateUrlsBatch(
            @RequestBody List<FileRequestDto> requestList,
            @RequestHeader("Authorization") String authHeader) {

        String jwtToken = authHeader.replace("Bearer ", "").trim();

        if (requestList.isEmpty()) {
            return new UploadBatchResponseDto();
        }

        int total = requestList.size();
        Long studentResponseId = System.currentTimeMillis();
        log.info("생성된 studentResponseId = {}", studentResponseId);

        // =============================
        // 🔥 1. 먼저 모든 DTO에 studentResponseId / index / total 세팅
        // =============================
        for (int i = 0; i < requestList.size(); i++) {
            FileRequestDto dto = requestList.get(i);
            dto.setStudent_response_id(studentResponseId);
            dto.setIndex(i + 1);
            dto.setTotal(total);
        }

        // =============================
        // 🔥 2. 이제 saveStudentResponse 호출 → total 값 존재함 🔥
        // =============================
        gradingServiceClient.saveStudentResponse(studentResponseId, requestList.get(0), jwtToken);
        log.info("StudentResponse 생성 요청 완료(id={})", studentResponseId);

        // =============================
        // 🔥 3. URL 생성 및 SSE 전송
        // =============================
        List<String> urlList = requestList.stream().map((r) -> {
            String url = s3Service.getUploadUrl(r);

            sink.tryEmitNext(ServerSentEvent.<String>builder()
                    .event("upload-url")
                    .data(url)
                    .build());

            log.info("발급된 URL = {} (index={}/{})", url, r.getIndex(), r.getTotal());
            return url;
        }).toList();

        return new UploadBatchResponseDto(studentResponseId, urlList);
    }

    @GetMapping("/sts/upload")
    public Map<String, Object> getUploadCredentials(@RequestParam String folder) {

        // 1. AWS STS 클라이언트 생성
        AwsBasicCredentials awsCreds = AwsBasicCredentials.create(accessKey, secretKey);
        StsClient stsClient = StsClient.builder()
                .region(Region.of(region))
                .credentialsProvider(StaticCredentialsProvider.create(awsCreds))
                .build();

        // 2. Role ARN 생성
        String roleArn = "arn:aws:iam::" + awsAccountId + ":role/" + roleName;

        // 3. 임시 credentials 발급
        AssumeRoleRequest roleRequest = AssumeRoleRequest.builder()
                .roleArn(roleArn)
                .roleSessionName("fastapi-upload-session")
                .durationSeconds(43200) // 12시간
                .build();

        AssumeRoleResponse roleResponse = stsClient.assumeRole(roleRequest);
        Credentials creds = roleResponse.credentials();

        // 4. 반환
        Map<String, Object> result = new HashMap<>();
        result.put("access_key_id", creds.accessKeyId());
        result.put("secret_access_key", creds.secretAccessKey());
        result.put("session_token", creds.sessionToken());
        result.put("expiration", creds.expiration());
        result.put("folder", folder);

        return result;
    }


    @GetMapping("/section")
    public Map<String, String> getSectionImagePresignedUrl(
            @RequestParam Long academyUserId,
            @RequestParam Long studentResponseId,
            @RequestParam int questionNumber) {

        // S3 key 생성
        String key = String.format(
                "section/%d/%d/%d/section.jpg",
                academyUserId,
                studentResponseId,
                questionNumber
        );

        // Presigned GET URL 생성
        String presignedUrl = s3Service.getPresignedGetUrl(key);

        Map<String, String> result = new HashMap<>();
        result.put("url", presignedUrl);
        result.put("key", key);

        log.info("📌 Section 조회 URL 발급: {}", key);

        return result;
    }



}
