package kr.ac.dankook.microservices.user.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class FindResponseDto {

    private String name;
    private String email;
    private String account_id;
    private String token;


}
