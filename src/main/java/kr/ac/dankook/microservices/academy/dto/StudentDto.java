package kr.ac.dankook.microservices.academy.dto;

import kr.ac.dankook.microservices.academy.entity.Student;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentDto {
    private Long student_id;
    private Long user_id;
    private String student_name;
    private String student_grade;
    private Long class_entity_id;
    private LocalDateTime created_at;
    private LocalDateTime updated_at;
}