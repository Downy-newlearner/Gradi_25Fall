package kr.ac.dankook.microservices.grading.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class GradingHistoryDto {
    private Long history_id;
    private Long student_response_id; // StudentResponse 엔티티 대신 ID만 사용
    private int total_score;
    private LocalDateTime grade_at;
    private Long grader_id;
}
