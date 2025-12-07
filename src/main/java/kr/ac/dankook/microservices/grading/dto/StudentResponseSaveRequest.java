package kr.ac.dankook.microservices.grading.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class StudentResponseSaveRequest {
    private Long studentResponseId;  // storage-service에서 전달
    private Long academy_user_id;
    private Long user_id;
    private Long class_id;
    private Long academy_id;
    private int total;
}
