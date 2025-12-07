package kr.ac.dankook.microservices.user.controller;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import kr.ac.dankook.microservices.common.dto.JwtToken;
import kr.ac.dankook.microservices.user.dto.*;
import kr.ac.dankook.microservices.user.entity.User;
import kr.ac.dankook.microservices.user.mapper.UserMapper;
import kr.ac.dankook.microservices.user.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;


@RestController
@RequiredArgsConstructor
@Slf4j
public class UserController {
    private final UserService userService;

    @PostMapping("/sign-up")
    public ResponseEntity<User> userSignUp(@RequestBody SignUpDto signUpDto) {
        User user = userService.userSignUp(signUpDto);
        return ResponseEntity.ok(user);
    }


    @PostMapping("/sign-in")
    public ResponseEntity<JwtToken> userSignIn(@RequestBody SignInDto signInDto, HttpSession session) {
        JwtToken jwtTokenDto = userService.userSignIn(signInDto);

        if (jwtTokenDto == null) {
            log.info("인증 실패");
            return ResponseEntity.badRequest().build();
        } else {
            log.info("로그인 성공");

            // 세션에 사용자 이메일 저장
            session.setAttribute("accountId", signInDto.getAccount_id());

            return ResponseEntity.ok(jwtTokenDto);
        }
    }


    @PostMapping("/sign-out")
    public ResponseEntity<String> logout(HttpServletRequest request) {
        return userService.logout(request);
    }



    @GetMapping("/users/check-accountId")
    public ResponseEntity<VerifyCodeResponse<Boolean>> checkAccountId(@RequestParam String accountId) {
        return ResponseEntity.ok(userService.isAccountIdDuplicate(accountId));
    }



    @PostMapping("/users/reset-password")
    public ResponseEntity<Map<String, Boolean>> resetPassword(@RequestBody PasswordResetRequest request) {
        try {
            userService.resetPassword(request);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false));
        }
    }



    @PostMapping("/change-password")
    public ResponseEntity<Map<String, Boolean>> changePassword(@RequestBody PasswordChangeRequest request) {
        try {
            userService.changePassword(request);
            return ResponseEntity.ok(Map.of("success", true));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false));
        }
    }





    @PostMapping("/send-code/{purpose}")
    public ResponseEntity<?> sendVerificationCode(
            @PathVariable String purpose,
            @RequestBody FindRequestDto request) {

        UserService.VerificationPurpose verificationPurpose =
                UserService.VerificationPurpose.valueOf(purpose.toUpperCase());

        userService.sendVerificationCode(request, verificationPurpose);

        return ResponseEntity.ok(Map.of(
                "success", true,
                "message", "인증번호가 발송되었습니다."
        ));
    }

    // 인증번호 검증
    @PostMapping("/verify/{purpose}")
    public ResponseEntity<?> verifyCode(
            @PathVariable String purpose,
            @RequestBody FindRequestDto request) {

        UserService.VerificationPurpose verificationPurpose =
                UserService.VerificationPurpose.valueOf(purpose.toUpperCase());

        VerifyCodeResponse<FindResponseDto> response = userService.verifyCode(
                request,
                verificationPurpose
        );

        return ResponseEntity.ok(response);
    }

    @GetMapping("/me")
    public ResponseEntity<UserDto> getCurrentUser() {
        User user = userService.getUser();

        if (user == null) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }

        // 엔티티를 그대로 노출하지 말고 DTO로 변환하는 것이 좋습니다
        UserDto userDto = UserMapper.toDto(user);

        return ResponseEntity.ok(userDto);
    }


//    @PostMapping("/{userId}/academies/{academyId}")
//    public String joinAcademy(@PathVariable Long userId, @PathVariable Long academyId) {
//
//
//        userAcademyService.registerToAcademy(userId, academyId);
//
//        // 2️⃣ 가입 이벤트 발행
//        UserAcademyEvent event = UserAcademyEvent.builder()
//                .userId(userId)
//                .academyId(academyId)
//                .action("JOIN")
//                .build();
//
//        userAcademyEventProducer.sendUserAcademyEvent(event);
//
//        return "User " + userId + " joined academy " + academyId;
//    }



}
