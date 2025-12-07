package kr.ac.dankook.microservices.grading.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StudentAnswerDto {
    private Long student_answer_id;
    private Long student_response_id;
    private Long chapter_id;
    private int page;
    private int question_number;
    private int sub_question_number;
    private String answer;
    private String section_url;
    private Boolean is_correct;
    private Double score;
}
