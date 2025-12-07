package kr.ac.dankook.microservices.storage.service;

import kr.ac.dankook.microservices.storage.dto.FileRequestDto;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PresignedGetObjectRequest;
import software.amazon.awssdk.services.s3.presigner.model.PutObjectPresignRequest;

import java.time.Duration;

@Service
@RequiredArgsConstructor
public class S3Service {

    private final S3Client s3Client;
    private final S3Presigner presigner;

    @Value("${aws.s3.bucket}")
    private String bucketName;

    /**
     * 단일 FileRequestDto에 대한 presigned URL 생성
     * key 형식: files/academyId/classId/academyUserId/studentResponseId/total/index/fileName
     */
    public String getUploadUrl(FileRequestDto requestDto) {
        String key = String.format(
                "files/%d/%d/%d/%d/%d/%d/%d/%s",
                requestDto.getAcademy_id(),
                requestDto.getClass_id(),
                requestDto.getUser_id(),
                requestDto.getAcademy_user_id(),
                requestDto.getStudent_response_id(),
                requestDto.getTotal(),
                requestDto.getIndex(),
                requestDto.getFile_name()
        );

        PutObjectRequest objectRequest = PutObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

        PutObjectPresignRequest presignRequest = PutObjectPresignRequest.builder()
                .putObjectRequest(objectRequest)
                .signatureDuration(Duration.ofMinutes(10))
                .build();

        return presigner.presignPutObject(presignRequest).url().toString();
    }


    public String getPresignedGetUrl(String key) {
        GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                .bucket(bucketName)
                .key(key)
                .build();

        PresignedGetObjectRequest presignedRequest =
                presigner.presignGetObject(r -> r
                        .signatureDuration(Duration.ofMinutes(10)) // 유효기간
                        .getObjectRequest(getObjectRequest)
                );

        return presignedRequest.url().toString();
    }

}
