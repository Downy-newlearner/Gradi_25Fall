package kr.ac.dankook.microservices.academy.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AcademyUserDto {
    private Long academy_user_id;
    private Long academy_id;
    private AcademyDto academy;
    private Long class_id;
    private Long user_id;
    private Long learner_id;
    private Character register_status;
}
