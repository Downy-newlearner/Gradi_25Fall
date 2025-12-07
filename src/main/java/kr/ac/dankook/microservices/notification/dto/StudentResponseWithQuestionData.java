package kr.ac.dankook.microservices.notification.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class StudentResponseWithQuestionData {

    @JsonProperty("student_response_id")
    private Long studentResponseId;

    @JsonProperty("question_number")
    private int questionNumber;
}
