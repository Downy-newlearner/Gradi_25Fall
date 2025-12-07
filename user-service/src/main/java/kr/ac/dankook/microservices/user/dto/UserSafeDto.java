package kr.ac.dankook.microservices.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@AllArgsConstructor
@Getter
@Setter
public class UserSafeDto {
    private Long user_id;
    private String name;
    private String ph;
}
