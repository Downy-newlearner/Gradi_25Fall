package kr.ac.dankook.microservices.user.dto;

import lombok.*;

@Data
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor

public class UserDto {

    private Long userId;
    private String email;
    private String account_id;
    private String name;
    private String phone_number;


    public UserDto(Long userId, String name, String phoneNumber, String email) {
        this.userId = userId;
        this.name = name;
        this.phone_number = phoneNumber;
        this.email = email;
    }
}
