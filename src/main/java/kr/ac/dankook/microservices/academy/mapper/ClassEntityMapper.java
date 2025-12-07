package kr.ac.dankook.microservices.academy.mapper;

import kr.ac.dankook.microservices.academy.dto.ClassEntityDto;
import kr.ac.dankook.microservices.academy.entity.Academy;
import kr.ac.dankook.microservices.academy.entity.ClassEntity;
import kr.ac.dankook.microservices.academy.entity.Teacher;

public class ClassEntityMapper {

    public static ClassEntityDto toDto(ClassEntity entity) {
        if (entity == null) return null;

        return ClassEntityDto.builder()
                .classId(entity.getClassEntityId())
                .teacherId(entity.getTeacher() != null ? entity.getTeacher().getTeacherId() : null)
                .academyId(entity.getAcademy() != null ? entity.getAcademy().getAcademyId() : null)
                .className(entity.getClassName())
                .build();
    }

    public static ClassEntity toEntity(ClassEntityDto dto) {
        if (dto == null) return null;

        ClassEntity entity = new ClassEntity();
        entity.setClassEntityId(dto.getClassId());
        entity.setClassName(dto.getClassName());

        // 관계는 ID만 설정 (Teacher, Academy는 Service에서 조회 후 주입)
        if (dto.getTeacherId() != null) {
            Teacher teacher = new Teacher();
            teacher.setTeacherId(dto.getTeacherId());
            entity.setTeacher(teacher);
        }

        if (dto.getAcademyId() != null) {
            Academy academy = new Academy();
            academy.setAcademyId(dto.getAcademyId());
            entity.setAcademy(academy);
        }

        return entity;
    }
}
