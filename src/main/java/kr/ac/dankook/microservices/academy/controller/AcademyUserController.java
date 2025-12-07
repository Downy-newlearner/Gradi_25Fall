package kr.ac.dankook.microservices.academy.controller;

import kr.ac.dankook.microservices.academy.dto.AcademyUserClassDto;
import kr.ac.dankook.microservices.academy.dto.AcademyUserDto;
import kr.ac.dankook.microservices.academy.dto.AcademyUserMappingDto;
import kr.ac.dankook.microservices.academy.entity.AcademyUser;
import kr.ac.dankook.microservices.academy.entity.ClassEntity;
import kr.ac.dankook.microservices.academy.service.AcademyUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/academy-users")
@RequiredArgsConstructor
public class AcademyUserController {

    private final AcademyUserService service;

    /**
     * ✅ 학원 가입 요청 (비동기)
     */
    @PostMapping("/join/request")
    public ResponseEntity<String> requestJoin(@RequestBody AcademyUserDto dto) {
        service.requestJoinAcademyAsync(dto);  // 🔹 비동기 처리
        return ResponseEntity.accepted().body("학원 가입 요청이 처리 중입니다.");
    }

    /**
     * ✅ 학원 가입 승인 (비동기)
     */
    @PostMapping("/{academyUserId}/approve")
    public ResponseEntity<String> approveJoin(@PathVariable Long academyUserId) {
        service.approveJoinAsync(academyUserId);  // 🔹 비동기 처리
        return ResponseEntity.accepted().body("가입 승인 요청이 처리 중입니다.");
    }

    /**
     * ✅ 학원 탈퇴 (비동기)
     */
    @DeleteMapping("/{academyUserId}/leave")
    public ResponseEntity<String> leaveAcademy(@PathVariable Long academyUserId) {
        service.leaveAcademyAsync(academyUserId);  // 🔹 비동기 처리
        return ResponseEntity.accepted().body("탈퇴 요청이 처리 중입니다.");
    }




    @GetMapping("/{userId}/academies")
    public ResponseEntity<List<AcademyUserDto>> getUserAcademyList(
            @PathVariable Long userId) {

        List<AcademyUserDto> result = service.getUserAcademyList(userId);

        if (result.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(result);
    }

    /**
     * ✅ academy_user_id 로 매핑 정보 조회
     */
    @GetMapping("/{academyUserId}/mapping")
    public ResponseEntity<AcademyUserMappingDto> getMappingByAcademyUserId(
            @PathVariable("academyUserId") Long academyUserId
    ) {
        AcademyUserMappingDto dto = service.findMappingByAcademyUserId(academyUserId);
        return ResponseEntity.ok(dto);
    }

    /**
     * 여러 academyUserId로 클래스 정보 조회 (리스트)
     * 요청 예시: GET /academy-users/classes?ids=10,11,12
     */
    @GetMapping("/classes")
    public ResponseEntity<List<AcademyUserClassDto>> getAcademyUserClasses(
            @RequestParam List<Long> ids) {

        List<AcademyUserClassDto> result = service.getAcademyUserClasses(ids);
        if (result.isEmpty()) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(result);
    }




}
