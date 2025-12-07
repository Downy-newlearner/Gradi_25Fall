package kr.ac.dankook.microservices.grading.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ExplanationRequest {
    private Long student_response_id;
    private Long user_id;
    private int academy_user_id;
    private int page_number;
    private int question_number;
    private String answer;
}
