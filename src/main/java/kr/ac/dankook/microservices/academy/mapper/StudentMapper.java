package kr.ac.dankook.microservices.academy.mapper;


import kr.ac.dankook.microservices.academy.dto.StudentDto;
import kr.ac.dankook.microservices.academy.entity.Student;
import org.springframework.stereotype.Component;

@Component
public class StudentMapper {

    public StudentDto toDto(Student student) {
        if (student == null) return null;

        return StudentDto.builder()
                .student_id(student.getStudentId())
                .user_id(student.getUserId())
                .student_name(student.getStudentName())
                .student_grade(student.getStudentGrade())
                .class_entity_id(student.getClassEntityId())
                .created_at(student.getCreatedAt())
                .updated_at(student.getUpdatedAt())
                .build();
    }

    public Student toEntity(StudentDto dto) {
        if (dto == null) return null;

        Student student = new Student();
        student.setStudentId(dto.getStudent_id());
        student.setUserId(dto.getUser_id());
        student.setStudentName(dto.getStudent_name());
        student.setStudentGrade(dto.getStudent_grade());
        student.setClassEntityId(dto.getClass_entity_id());
        student.setCreatedAt(dto.getCreated_at());
        student.setUpdatedAt(dto.getUpdated_at());
        return student;
    }
}
