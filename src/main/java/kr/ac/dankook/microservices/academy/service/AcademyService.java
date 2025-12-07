package kr.ac.dankook.microservices.academy.service;

import kr.ac.dankook.microservices.academy.dto.AcademyDto;
import kr.ac.dankook.microservices.common.dto.AcademyUserEvent;
import kr.ac.dankook.microservices.academy.dto.NearbyAcademyDto;
import kr.ac.dankook.microservices.academy.entity.Academy;
import kr.ac.dankook.microservices.academy.entity.AcademyUser;
import kr.ac.dankook.microservices.academy.mapper.AcademyMapper;
import kr.ac.dankook.microservices.academy.repository.AcademyRepository;
import kr.ac.dankook.microservices.academy.repository.AcademyUserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.util.List;

@Slf4j
@Service
public class AcademyService {
    private static final String CODE_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    private static final int CODE_LENGTH = 8; // 원하는 길이
    private static final SecureRandom RANDOM = new SecureRandom();

    @Autowired
    private AcademyRepository academyRepository;

    @Autowired
    private AcademyUserRepository academyUserRepository;

    @Autowired
    private AcademyUserEventProducer producer;


    /**
     * 랜덤 문자열 생성
     */
    private String generateRandomCode() {
        StringBuilder sb = new StringBuilder(CODE_LENGTH);
        for (int i = 0; i < CODE_LENGTH; i++) {
            int idx = RANDOM.nextInt(CODE_CHARS.length());
            sb.append(CODE_CHARS.charAt(idx));
        }
        return sb.toString();
    }



    /**
     * 랜덤 학원 코드 생성 후 DB 중복 체크
     */
    public String generateUniqueAcademyCode() {
        String code;
        do {
            code = generateRandomCode();
        } while (academyRepository.existsByAcademyCode(code)); // 중복 체크
        return code;
    }


    public Academy create(AcademyDto academyDto) {
        Academy academy = AcademyMapper.toEntity(academyDto);
        academy.setAcademyCode(null);
        academy.setAcademyCode(generateUniqueAcademyCode()); // 코드 생성
        return academyRepository.save(academy);
    }

    /**
     * 사용자 위치(lat, lng) 기준 반경(radiusKm) 내 학원 조회 (거리 가까운 순, 페이지네이션)
     *
     * @param lat      사용자 위도
     * @param lng      사용자 경도
     * @param radiusKm 반경 (km)
     * @param page     페이지 번호 (0부터 시작)
     * @param size     페이지당 학원 개수
     * @return 근처 학원 리스트 (DTO)
     */
    public List<NearbyAcademyDto> findNearbyWithDistance(double lat, double lng, double radiusKm, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);

        List<Academy> academies = academyRepository.findNearbyAcademiesWithPage(lat, lng, radiusKm, pageable);

        return AcademyMapper.toNearbyDtoList(academies, lat, lng);
    }

    public Academy findById(Long id) {
        return academyRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Academy not found"));
    }

    public Academy update(AcademyDto updatedDto) {
        Academy academy = AcademyMapper.toEntity(updatedDto);
        return academyRepository.save(academy);
    }

    public void delete(String code) {
        academyRepository.deleteByAcademyCode(code);
    }



}
