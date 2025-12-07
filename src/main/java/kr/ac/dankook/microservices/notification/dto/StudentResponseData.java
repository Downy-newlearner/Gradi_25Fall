package kr.ac.dankook.microservices.notification.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class StudentResponseData {

    @JsonProperty("student_response_id")
    private Long studentResponseId;
}
