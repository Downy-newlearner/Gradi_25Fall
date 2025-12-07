//package kr.ac.dankook.microservices.grading.mapper;
//
//import kr.ac.dankook.microservices.grading.dto.StudentAcademyCacheDto;
//
//public class StudentAcademyCacheMapper {
//    public static StudentAcademyCacheDto toDto(StudentAcademyCache entity) {
//        if (entity == null) return null;
//        return StudentAcademyCacheDto.builder()
//                .studentAcademyId(entity.getStudentAcademyId())
//                .studentId(entity.getStudentId())
//                .academyId(entity.getAcademyId())
//                .academyName(entity.getAcademyName())
//                .registerStatus(entity.getRegisterStatus())
//                .updatedAt(entity.getUpdatedAt())
//                .build();
//    }
//
//    public static StudentAcademyCache toEntity(StudentAcademyCacheDto dto) {
//        if (dto == null) return null;
//        StudentAcademyCache entity = new StudentAcademyCache();
//        entity.setStudentAcademyId(dto.getStudentAcademyId());
//        entity.setStudentId(dto.getStudentId());
//        entity.setAcademyId(dto.getAcademyId());
//        entity.setAcademyName(dto.getAcademyName());
//        entity.setRegisterStatus(dto.getRegisterStatus());
//        entity.setUpdatedAt(dto.getUpdatedAt());
//        return entity;
//    }
//}
