package kr.ac.dankook.microservices.academy.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class NearbyAcademyDto {
    private String academyName;
    private String academyCode;
    private String academyRoadAddress;
    private double distanceKm; // 소수 첫째 자리까지
}
