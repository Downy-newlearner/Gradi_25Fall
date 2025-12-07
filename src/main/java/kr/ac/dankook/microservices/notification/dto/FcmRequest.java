package kr.ac.dankook.microservices.notification.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class FcmRequest<T> {
    private Long user_id;
    private String token;
    private String title;
    private String body;

    private T data;   // 🔥 제너릭 - 원하는 어떤 형태도 가능
}
