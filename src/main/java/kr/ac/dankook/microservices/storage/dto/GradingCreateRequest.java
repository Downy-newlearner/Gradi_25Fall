package kr.ac.dankook.microservices.storage.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
@NoArgsConstructor
public class GradingCreateRequest {
    private Long academy_id;
    private Long user_id;
    private Long class_id;
}
