package kr.ac.dankook.microservices.academy.controller;

import kr.ac.dankook.microservices.academy.dto.AcademyDto;
import kr.ac.dankook.microservices.academy.dto.NearbyAcademyDto;
import kr.ac.dankook.microservices.academy.entity.Academy;
import kr.ac.dankook.microservices.academy.service.AcademyService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@Slf4j
@RestController
@RequiredArgsConstructor

public class AcademyController {

    @Autowired
    AcademyService academyService;

    @PostMapping
    public ResponseEntity<?> createAcademy(@RequestBody AcademyDto academyDto) {
        Academy academy =  academyService.create(academyDto);
        return ResponseEntity.ok(academy);
    }



    /**
     * 사용자 위치 기준 반경 내 근처 학원 조회
     *
     * @param lat    사용자 위도
     * @param lng    사용자 경도
     * @param radius 반경 (단위: km, 기본값: 5km)
     * @return 근처 학원 리스트 (DTO)
     */
    /**
     * 근처 학원 조회 (거리 포함, 가까운 순, 페이지네이션)
     *
     * @param lat    사용자 위도
     * @param lng    사용자 경도
     * @param radius 반경 km (기본 5)
     * @param page   페이지 번호 (0부터 시작)
     * @param size   페이지당 학원 개수 (기본 10)
     */
    @GetMapping("/nearby")
    public List<NearbyAcademyDto> getNearbyAcademies(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "5") double radius,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return academyService.findNearbyWithDistance(lat, lng, radius, page, size);
    }


    @GetMapping("/{id}")
    public Academy getAcademy(@PathVariable Long id) {
        return academyService.findById(id);
    }

    @PutMapping()
    public Academy updateAcademy(@RequestBody AcademyDto academyDto) {
        return academyService.update(academyDto);
    }

    @DeleteMapping("/{code}")
    public void deleteAcademy(@PathVariable String code) {
        academyService.delete(code);
    }


}
