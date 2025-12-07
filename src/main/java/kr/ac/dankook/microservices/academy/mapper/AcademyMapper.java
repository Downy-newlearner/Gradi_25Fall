package kr.ac.dankook.microservices.academy.mapper;

import kr.ac.dankook.microservices.academy.dto.AcademyDto;
import kr.ac.dankook.microservices.academy.dto.NearbyAcademyDto;
import kr.ac.dankook.microservices.academy.entity.Academy;

import java.util.List;
import java.util.stream.Collectors;

public class AcademyMapper {

    public static AcademyDto toDto(Academy academy) {
        if (academy == null) {
            return null;
        }
        return AcademyDto.builder()
                .academy_name(academy.getAcademyName())
                .academy_code(academy.getAcademyCode())
                .academy_description(academy.getAcademyDescription())
                .academy_phone(academy.getAcademyPhone())
                .academy_email(academy.getAcademyEmail())
                .academy_website(academy.getAcademyWebsite())
                .academy_road_address(academy.getAcademyRoadAddress())
                .academy_detail_address(academy.getAcademyDetailAddress())
                .academy_latitude(academy.getAcademyLatitude())
                .academy_longitude(academy.getAcademyLongitude())
                .build();
    }

    public static Academy toEntity(AcademyDto dto) {
        if (dto == null) {
            return null;
        }
        Academy academy = new Academy();
        academy.setAcademyName(dto.getAcademy_name());
        academy.setAcademyCode(dto.getAcademy_code());
        academy.setAcademyDescription(dto.getAcademy_description());
        academy.setAcademyPhone(dto.getAcademy_phone());
        academy.setAcademyEmail(dto.getAcademy_email());
        academy.setAcademyWebsite(dto.getAcademy_website());
        academy.setAcademyRoadAddress(dto.getAcademy_road_address());
        academy.setAcademyDetailAddress(dto.getAcademy_detail_address());
        academy.setAcademyLatitude(dto.getAcademy_latitude());
        academy.setAcademyLongitude(dto.getAcademy_longitude());
        return academy;
    }

    // 단일 객체 매핑 (거리 계산 포함)
    public static NearbyAcademyDto toNearbyDto(Academy academy, double userLat, double userLng) {
        if (academy == null) return null;

        double distance = calculateDistance(userLat, userLng, academy.getAcademyLatitude(), academy.getAcademyLongitude());

        // 소수 첫째자리까지만
        distance = Math.round(distance * 10) / 10.0;

        return NearbyAcademyDto.builder()
                .academyName(academy.getAcademyName())
                .academyCode(academy.getAcademyCode())
                .academyRoadAddress(academy.getAcademyRoadAddress())
                .distanceKm(distance)
                .build();
    }

    // 리스트 매핑
    public static List<NearbyAcademyDto> toNearbyDtoList(List<Academy> academies, double userLat, double userLng) {
        if (academies == null) return null;

        return academies.stream()
                .map(a -> toNearbyDto(a, userLat, userLng))
                .collect(Collectors.toList());
    }

    // Haversine formula로 거리 계산 (km)
    private static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
        final int R = 6371; // 지구 반지름(km)
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);

        double a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
                        Math.sin(dLng/2) * Math.sin(dLng/2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

        return R * c;
    }
}

