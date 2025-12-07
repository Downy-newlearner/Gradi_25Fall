package kr.ac.dankook.microservices.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FindRequestDto {

    private String account_id;
    private String name;
    private String email;
    private String code;
}
