package kr.ac.dankook.microservices.grading.dto;

import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AssessmentDto {
    private Long assess_id;
    private Long book_id;
    private Long assigner_id;
    private Long assignee_id;
    private int assess_start_page;
    private int assess_end_page;
    private LocalDateTime assess_deadline;
    private String assess_name;
    private String assess_type;
    private String assess_status;

}
