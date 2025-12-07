package kr.ac.dankook.microservices.grading.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentAcademyCacheDto {
    private Long studentAcademyId;
    private Long studentId;
    private Long academyId;
    private String academyName;
    private char registerStatus;
    private LocalDateTime updatedAt;
}
