package kr.ac.dankook.microservices.grading.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
public class QuestionDto {


    private Long question_id;
    private Long chapter_id;
    private Integer page;
    private Double point;
    private Integer question_number;
    private Integer sub_question_number;
    private String answer;
    private Integer answer_count;
}
