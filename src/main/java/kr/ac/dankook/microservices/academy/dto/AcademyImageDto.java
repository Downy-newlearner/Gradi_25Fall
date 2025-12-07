package kr.ac.dankook.microservices.academy.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AcademyImageDto {


    private String academy_code;

    // 전체 이미지 URL 리스트
    private List<String> academy_image_urls;

    // 대표 이미지 URL
    private String main_image_url;

}

