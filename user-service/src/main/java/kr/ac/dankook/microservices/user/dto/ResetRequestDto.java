package kr.ac.dankook.microservices.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ResetRequestDto {
    private String email;
}
