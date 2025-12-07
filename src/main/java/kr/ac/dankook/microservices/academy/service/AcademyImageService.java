package kr.ac.dankook.microservices.academy.service;

import kr.ac.dankook.microservices.academy.dto.AcademyImageDto;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.ListObjectsV2Request;
import software.amazon.awssdk.services.s3.model.S3Object;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AcademyImageService {


    private final S3Client s3Client;

    @Value("${aws.s3.bucket}")
    private String bucket;

    @Value("${aws.s3.cloudfront-domain}")
    private String cloudfrontDomain;

    public AcademyImageService(S3Client s3Client) {
        this.s3Client = s3Client;
    }

    public List<AcademyImageDto> getMainImages(List<String> academyCodes) {
        return academyCodes.stream()
                .map(this::getAcademyImages) // 기존 메서드 재사용
                .map(dto -> AcademyImageDto.builder()
                        .academy_code(dto.getAcademy_code())
                        .main_image_url(dto.getMain_image_url())
                        .build())
                .collect(Collectors.toList());
    }



    public AcademyImageDto getAcademyImages(String academyCode) {
        String prefix = "academy/" + academyCode + "/";

        ListObjectsV2Request req = ListObjectsV2Request.builder()
                .bucket(bucket)
                .prefix(prefix)
                .build();

        List<String> imageUrls = s3Client.listObjectsV2(req)
                .contents()
                .stream()
                .map(S3Object::key)
                .filter(key -> !key.endsWith("/")) // 폴더 제외
                .map(key -> cloudfrontDomain + "/" + key)
                .collect(Collectors.toList());

        // 대표 이미지: 항상 첫 번째 이미지
        String mainImageUrl = imageUrls.isEmpty() ? null : imageUrls.get(0);

        return AcademyImageDto.builder()
                .academy_code(academyCode)
                .academy_image_urls(imageUrls)
                .main_image_url(mainImageUrl)
                .build();
    }






}
