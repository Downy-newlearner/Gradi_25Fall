package kr.ac.dankook.microservices.academy.dto;


import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ClassEntityDto {
    private Long classId;
    private Long teacherId;
    private Long academyId;
    private String className;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
