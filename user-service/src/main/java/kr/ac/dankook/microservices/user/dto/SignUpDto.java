package kr.ac.dankook.microservices.user.dto;


import lombok.Data;

@Data
public class SignUpDto {
    private String email;
    private String account_id;
    private String password;
    private String name;
    private String phone_number;
}
