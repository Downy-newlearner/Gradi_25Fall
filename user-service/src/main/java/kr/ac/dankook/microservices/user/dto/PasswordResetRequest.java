// com.checkmate.ai.dto.PasswordChangeRequest.java
package kr.ac.dankook.microservices.user.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class PasswordResetRequest {
    private String token;
    private String new_password;
}


