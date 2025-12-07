package kr.ac.dankook.microservices.user.dto;;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class VerifyCodeResponse<T> {
    private boolean success;
    private T data;
}
