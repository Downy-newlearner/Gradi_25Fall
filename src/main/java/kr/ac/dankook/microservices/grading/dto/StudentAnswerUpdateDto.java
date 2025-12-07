package kr.ac.dankook.microservices.grading.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class StudentAnswerUpdateDto {
    private Long student_answer_id;
    private Long student_response_id;
    private Long chapter_id;
    private int page;
    private int question_number;
    private int sub_question_number;
    private String answer;
}
