package kr.ac.dankook.microservices.academy.dto;

import jakarta.persistence.Column;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AcademyDto {
    private String academy_name;
    private String academy_code;
    private String academy_description;
    private String academy_phone;
    private String academy_email;
    private String academy_website;
    private String academy_road_address;     // 도로명 주소
    private String academy_detail_address;    // 건물명 + 층 정보
    private double academy_latitude;        // 위도
    private double academy_longitude;       // 경도
}

