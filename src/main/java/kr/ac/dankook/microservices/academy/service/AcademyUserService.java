package kr.ac.dankook.microservices.academy.service;

import kr.ac.dankook.microservices.academy.dto.AcademyDto;
import kr.ac.dankook.microservices.academy.dto.AcademyUserClassDto;
import kr.ac.dankook.microservices.academy.dto.AcademyUserDto;
import kr.ac.dankook.microservices.academy.dto.AcademyUserMappingDto;
import kr.ac.dankook.microservices.academy.entity.Academy;
import kr.ac.dankook.microservices.academy.entity.AcademyUser;
import kr.ac.dankook.microservices.academy.entity.ClassEntity;
import kr.ac.dankook.microservices.academy.mapper.AcademyMapper;
import kr.ac.dankook.microservices.academy.mapper.AcademyUserMapper;
import kr.ac.dankook.microservices.academy.repository.AcademyRepository;
import kr.ac.dankook.microservices.academy.repository.AcademyUserRepository;
import kr.ac.dankook.microservices.academy.repository.ClassEntityRepository;
import kr.ac.dankook.microservices.common.dto.AcademyUserEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;

@Service
@RequiredArgsConstructor
@Slf4j
public class AcademyUserService {

    private final AcademyUserRepository repository;
    private final AcademyRepository academyRepository;
    private final ClassEntityRepository classEntityRepository;
    private final AcademyUserMapper academyUserMapper;
    private final AcademyUserEventProducer eventProducer; // Kafka 발행용, 내부에서 String(JSON)으로 직렬화하여 전송

    /**
     * 학원 가입 요청 (P 상태)
     * - 저장 후 JOIN_REQUEST 이벤트 발행 (String JSON)
     */
    @Transactional
    public AcademyUserDto requestJoinAcademy(AcademyUserDto dto) {

        // 1) academyCode → academyId 찾기 (DTO에서 academy_id는 사용 안 함)
        Academy academy = academyRepository.findByAcademyCode(dto.getAcademy().getAcademy_code())
                .orElseThrow(() -> new RuntimeException("Academy not found"));

        Long academyId = academy.getAcademyId();

        // 2) 기존 가입 정보 조회
        Optional<AcademyUser> existing =
                repository.findByUserIdAndAcademyId(dto.getUser_id(), academyId);

        AcademyUser academyUser;

        if (existing.isPresent()) {
            academyUser = existing.get();
            academyUser.setRegisterStatus('P');
            // 필요한 경우 classId/learnerId 업데이트 가능
            if (dto.getClass_id() != null) academyUser.setClassId(dto.getClass_id());
            if (dto.getLearner_id() != null) academyUser.setLearnerId(dto.getLearner_id());
        } else {
            academyUser = AcademyUser.builder()
                    .academyId(academyId)   // 절대로 NULL 될 수 없음
                    .userId(dto.getUser_id())
                    .classId(dto.getClass_id())
                    .learnerId(dto.getLearner_id())
                    .registerStatus('P')
                    .build();
        }

        // 3) DB 저장
        AcademyUser saved = repository.save(academyUser);
        log.info("AcademyUser saved: {}", saved);

        // 4) JOIN_REQUEST 이벤트 생성 및 발행 (String JSON 전송을 가정)
        try {
            AcademyUserEvent event = new AcademyUserEvent();
            event.setAction("JOIN_REQUEST");
            event.setAcademy_user_id(saved.getAcademyUserId());
            event.setUser_id(saved.getUserId());
            event.setAcademy_name(academy.getAcademyName());
            event.setAcademy_code(academy.getAcademyCode());

            eventProducer.sendEvent(event);
            log.info("Sent JOIN_REQUEST event for academyUserId={}", saved.getAcademyUserId());
        } catch (Exception e) {
            // 이벤트 발행 실패는 로깅만 하고 흐름은 이어갈지 정책에 따라 변경 가능
            log.error("Failed to send JOIN_REQUEST event for academyUserId={}", saved.getAcademyUserId(), e);
        }

        // 5) DTO 반환
        return academyUserMapper.toDto(saved);
    }


    /**
     * 학원 가입 승인 (Pending -> Y)
     */
    @Transactional
    public void approveJoin(Long academyUserId) {
        AcademyUser user = repository.findById(academyUserId)
                .orElseThrow(() -> new RuntimeException("AcademyUser not found"));

        user.setRegisterStatus('Y');
        AcademyUser updated = repository.save(user);

        Academy academy = academyRepository.findById(user.getAcademyId())
                .orElseThrow(() -> new RuntimeException("Academy not found"));

        AcademyUserEvent event = new AcademyUserEvent();
        event.setAction("JOIN_APPROVED");
        event.setAcademy_user_id(updated.getAcademyUserId());
        event.setUser_id(updated.getUserId());
        event.setAcademy_name(academy.getAcademyName());
        event.setAcademy_code(academy.getAcademyCode());

        try {
            eventProducer.sendEvent(event);
            log.info("Sent JOIN_APPROVED event for academyUserId={}", academyUserId);
        } catch (Exception e) {
            log.error("Failed to send JOIN_APPROVED event for academyUserId={}", academyUserId, e);
        }

        log.info("✅ 학원 가입 승인 완료 - academyUserId={}", academyUserId);
    }

    /**
     * 학원 탈퇴
     */
    @Transactional
    public boolean leaveAcademy(Long academyUserId) {
        Optional<AcademyUser> opt = repository.findById(academyUserId);
        if (opt.isEmpty()) return false;

        AcademyUser user = opt.get();
        Academy academy = academyRepository.findById(user.getAcademyId())
                .orElseThrow(() -> new RuntimeException("Academy not found"));

        repository.delete(user);

        AcademyUserEvent event = new AcademyUserEvent();
        event.setAction("LEAVE");
        event.setAcademy_user_id(user.getAcademyUserId());
        event.setUser_id(user.getUserId());
        event.setAcademy_name(academy.getAcademyName());
        event.setAcademy_code(academy.getAcademyCode());

        try {
            eventProducer.sendEvent(event);
            log.info("Sent LEAVE event for academyUserId={}", academyUserId);
        } catch (Exception e) {
            log.error("Failed to send LEAVE event for academyUserId={}", academyUserId, e);
        }

        log.info("✅ 학원 탈퇴 완료 - academyUserId={}", academyUserId);
        return true;
    }

    /**
     * 비동기 버전: 백그라운드에서 실행
     */
    @Async("asyncExecutor")
    public CompletableFuture<Void> requestJoinAcademyAsync(AcademyUserDto dto) {
        requestJoinAcademy(dto);
        return CompletableFuture.completedFuture(null);
    }

    @Async("asyncExecutor")
    public CompletableFuture<Void> approveJoinAsync(Long academyUserId) {
        approveJoin(academyUserId);
        return CompletableFuture.completedFuture(null);
    }

    @Async("asyncExecutor")
    public CompletableFuture<Void> leaveAcademyAsync(Long academyUserId) {
        leaveAcademy(academyUserId);
        return CompletableFuture.completedFuture(null);
    }


    /**
     * 특정 userId로 중복 제거된 학원 목록 조회 + DTO 변환
     */
    public List<AcademyUserDto> getUserAcademyList(Long userId) {

        List<AcademyUser> list = repository.findDistinctByUserId(userId);

        return list.stream()
                .map(au -> {

                    // Academy 엔티티 로드
                    Academy academy = null;
                    if (au.getAcademyId() != null) {
                        academy = academyRepository.findById(au.getAcademyId())
                                .orElse(null);
                    }

                    // Academy → AcademyDto 매핑
                    AcademyDto academyDto = AcademyMapper.toDto(academy);

                    // AcademyUser → AcademyUserDto 변환
                    return AcademyUserDto.builder()
                            .academy_user_id(au.getAcademyUserId())
                            .academy_id(au.getAcademyId())
                            .academy(academyDto)
                            .class_id(au.getClassId())
                            .user_id(au.getUserId())
                            .learner_id(au.getLearnerId())
                            .register_status(au.getRegisterStatus())
                            .build();
                })
                .toList();
    }

    public AcademyUserMappingDto findMappingByAcademyUserId(Long academyUserId) {
        AcademyUser entity = repository.findById(academyUserId)
                .orElseThrow(() -> new RuntimeException("해당 academy_user_id가 존재하지 않습니다."));

        return new AcademyUserMappingDto(
                entity.getAcademyUserId(),
                entity.getUserId(),
                entity.getClassId(),
                entity.getAcademyId()
        );
    }

    /**
     * 여러 academyUserId로 클래스 이름 조회 후 academyUserId ↔ className 리스트 반환
     */
    public List<AcademyUserClassDto> getAcademyUserClasses(List<Long> academyUserIds) {
        List<AcademyUserClassDto> result = new ArrayList<>();
        for (Long userId : academyUserIds) {
            Optional<AcademyUser> userOpt = repository.findById(userId);
            if (userOpt.isEmpty() || userOpt.get().getClassId() == null) continue;

            classEntityRepository.findById(userOpt.get().getClassId())
                    .ifPresent(classEntity -> result.add(new AcademyUserClassDto(userId, classEntity.getClassName())));
        }
        return result;
    }
}
