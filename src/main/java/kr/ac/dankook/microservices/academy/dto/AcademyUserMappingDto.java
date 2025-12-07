package kr.ac.dankook.microservices.academy.dto;

import lombok.*;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class AcademyUserMappingDto {
    private Long academy_user_id;
    private Long user_id;
    private Long class_id;
    private Long academy_id;
}
