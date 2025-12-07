package kr.ac.dankook.microservices.notification.controller;


import kr.ac.dankook.microservices.notification.dto.FcmRequest;
import kr.ac.dankook.microservices.notification.service.FcmService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
public class NotificationController {

    @Autowired
    private FcmService fcmService;



    /**
     * FCM 토큰 등록 (로그인 시 클라이언트에서 호출)
     */
    @PostMapping("/activate")
    public String activate(@RequestBody FcmRequest fcmRequest) {
        fcmService.activateToken(fcmRequest);
        return "✅ FCM 토큰 등록 완료";
    }

    /**
     * 특정 사용자에게 푸시 전송
     */
    @PostMapping("/send")
    public String send(@RequestBody FcmRequest fcmRequest) {
        fcmService.sendToUser(fcmRequest);
        return "✅ 푸시 전송 요청 완료";
    }
}
