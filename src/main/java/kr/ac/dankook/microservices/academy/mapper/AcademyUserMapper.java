package kr.ac.dankook.microservices.academy.mapper;

import kr.ac.dankook.microservices.academy.dto.AcademyUserDto;
import kr.ac.dankook.microservices.academy.entity.AcademyUser;
import org.springframework.stereotype.Component;

@Component
public class AcademyUserMapper {

    /**
     * ✅ DTO → Entity 변환
     */
    public AcademyUser toEntity(AcademyUserDto dto) {
        if (dto == null) return null;

        return AcademyUser.builder()
                .academyUserId(dto.getAcademy_user_id())
                .academyId(dto.getAcademy_id())
                .userId(dto.getUser_id())
                .classId(dto.getClass_id())
                .learnerId(dto.getLearner_id())
                .registerStatus(dto.getRegister_status() != null ? dto.getRegister_status() : 'Y')
                .build();
    }

    /**
     * ✅ Entity 업데이트용 (부분 갱신)
     */
    public void updateEntity(AcademyUserDto dto, AcademyUser entity) {
        if (dto == null || entity == null) return;

        if (dto.getAcademy_id() != null) entity.setAcademyId(dto.getAcademy_id());
        if (dto.getUser_id() != null) entity.setUserId(dto.getUser_id());
        if (dto.getClass_id() != null) entity.setClassId(dto.getClass_id());
        if (dto.getLearner_id() != null) entity.setLearnerId(dto.getLearner_id());
        if (dto.getRegister_status() != null) entity.setRegisterStatus(dto.getRegister_status());
    }


    public AcademyUserDto toDto(AcademyUser entity) {
        if (entity == null) return null;

        return AcademyUserDto.builder()
                .academy_user_id(entity.getAcademyUserId())
                .academy_id(entity.getAcademyId())
                .user_id(entity.getUserId())
                .class_id(entity.getClassId())
                .learner_id(entity.getLearnerId())
                .register_status(entity.getRegisterStatus())
                .build();
    }
}
