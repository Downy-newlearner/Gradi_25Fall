package kr.ac.dankook.microservices.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FindIdVerifyDto {

    private String email;
    private String code;

}
