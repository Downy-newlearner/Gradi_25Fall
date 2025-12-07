package kr.ac.dankook.microservices.user.dto;

import lombok.Data;

@Data
public class SignInDto {
    private String account_id;
    private String password;


}