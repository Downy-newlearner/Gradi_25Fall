package kr.ac.dankook.microservices.user.service;


import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import jakarta.servlet.http.HttpServletRequest;
import kr.ac.dankook.microservices.common.dto.CustomUserDetails;
import kr.ac.dankook.microservices.common.dto.JwtToken;
import kr.ac.dankook.microservices.common.security.JwtTokenProvider;
import kr.ac.dankook.microservices.user.dto.*;
import kr.ac.dankook.microservices.user.entity.User;
import kr.ac.dankook.microservices.user.mapper.UserMapper;
import kr.ac.dankook.microservices.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

import org.springframework.beans.factory.support.BeanDefinitionRegistryPostProcessor;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;

import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.authentication.builders.AuthenticationManagerBuilder;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.Optional;
import java.util.Random;
import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class UserService {


    private final UserRepository userRepository;

    private final AuthenticationManagerBuilder authenticationManagerBuilder;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordEncoder passwordEncoder;
    private final JavaMailSender mailSender;
    private final RedisTemplate<String, String> redisTemplate;
    private final BeanDefinitionRegistryPostProcessor springSecurityPathPatternParserBeanDefinitionRegistryPostProcessor;


    public enum VerificationPurpose {
        FIND_ACCOUNT,
        RESET_PASSWORD,
        SIGN_UP  // 회원가입 이메일 인증
    }


    private static final int CODE_LENGTH = 6;
    private static final int CODE_TTL_MINUTES = 5;

    @Transactional
    public User userSignUp(SignUpDto signUpDto) {
        if (userRepository.findByEmail(signUpDto.getEmail()).isPresent()) {
            throw new IllegalArgumentException("User ID already exists!");
        }

        String encodedPassword = passwordEncoder.encode(signUpDto.getPassword());
        User currentUser = new User(
                signUpDto.getAccount_id(),
                signUpDto.getEmail(),
                encodedPassword, signUpDto.getName(),
                signUpDto.getPhone_number());
        userRepository.save(currentUser);
        return currentUser;

    }

    @Transactional
    public JwtToken userSignIn(SignInDto signInDto) {
        User user = userRepository.findByAccountId(signInDto.getAccount_id())
                .orElseThrow(() -> new UsernameNotFoundException("해당 ID를 찾을 수 없습니다."));

        if (!passwordEncoder.matches(signInDto.getPassword(), user.getPassword())) {
            throw new BadCredentialsException("비밀번호가 일치하지 않습니다.");
        }

        UsernamePasswordAuthenticationToken authenticationToken =
                new UsernamePasswordAuthenticationToken(signInDto.getAccount_id(), signInDto.getPassword());

        Authentication authentication;
        try {
            authentication = authenticationManagerBuilder.getObject().authenticate(authenticationToken);
        } catch (BadCredentialsException e) {
            log.error("인증 실패: {}", e.getMessage());
            return null;
        }

        if (!authentication.isAuthenticated()) {
            return null;
        }

        return jwtTokenProvider.generateToken(authentication);
    }



    public VerifyCodeResponse<Boolean> isAccountIdDuplicate(String accountId) {
        boolean exists = userRepository.existsByAccountId(accountId);
        return new VerifyCodeResponse<>(!exists, null);
    }


    public User getUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();

        Optional<User> currentUser = userRepository.findByAccountId(userDetails.getAccountId());

        if (currentUser.isEmpty()) {
            log.info("조회된 User가 없습니다");
            return null;
        }

        // Use UserMapper to convert User to UserDto
        return currentUser.get();
    }


    public void changePassword(PasswordChangeRequest request) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        String accountId = authentication.getName(); // principal이 accountId라면

        User user = userRepository.findByAccountId(accountId)
                .orElseThrow(() -> new IllegalArgumentException("해당 사용자를 찾을 수 없습니다."));

        if (!passwordEncoder.matches(request.getCurrent_password(), user.getPassword())) {
            throw new IllegalArgumentException("현재 비밀번호가 일치하지 않습니다.");
        }

        user.setPassword(passwordEncoder.encode(request.getNew_password()));
        userRepository.save(user);
    }

    public void resetPassword(PasswordResetRequest request) {
        if (!jwtTokenProvider.validateResetPasswordToken(request.getToken())) {
            throw new IllegalArgumentException("유효하지 않거나 만료된 토큰입니다.");
        }

        String email = jwtTokenProvider.getEmailFromResetPasswordToken(request.getToken());

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new IllegalArgumentException("해당 이메일의 사용자가 존재하지 않습니다."));

        user.setPassword(passwordEncoder.encode(request.getNew_password()));
        userRepository.save(user);
    }





    public ResponseEntity<String> logout(HttpServletRequest request) {
        String token = jwtTokenProvider.resolveToken(request);
        if (token == null) {
            log.warn("로그아웃 실패: 토큰이 존재하지 않음");
            return ResponseEntity.badRequest().body("토큰이 없습니다.");
        }

        if (!jwtTokenProvider.validateToken(token)) {
            log.warn("로그아웃 실패: 유효하지 않은 토큰");
            return ResponseEntity.badRequest().body("유효하지 않은 토큰입니다.");
        }

        try {
            long ttl = jwtTokenProvider.getExpiration(token);
            if (ttl > 0) {
                redisTemplate.opsForValue().set(token, "blacklisted", ttl, TimeUnit.MILLISECONDS);
            } else {
                log.warn("블랙리스트 등록 불가, TTL={}", ttl);
            }

            SecurityContextHolder.clearContext();
            log.info("로그아웃 성공: 토큰 블랙리스트 추가됨");
            return ResponseEntity.ok("로그아웃 되었습니다.");
        } catch (Exception e) {
            log.error("로그아웃 처리 중 오류 발생: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body("로그아웃 처리 중 오류가 발생했습니다.");
        }
    }


    public void sendVerificationCode(FindRequestDto request, VerificationPurpose purpose) {
        String email = request.getEmail();
        String name = request.getName();
        String accountId = request.getAccount_id();

        // 사용자 존재 확인
        if (purpose == VerificationPurpose.FIND_ACCOUNT) {
            userRepository.findByEmailAndName(email, name)
                    .orElseThrow(() -> new IllegalArgumentException("해당 이메일의 사용자가 존재하지 않습니다."));
        }

        if (purpose == VerificationPurpose.RESET_PASSWORD) {
            userRepository.findByEmailAndNameAndAccountId(email, name, accountId)
                    .orElseThrow(() -> new IllegalArgumentException("해당 정보(이메일, 이름, 아이디)에 해당하는 사용자가 존재하지 않습니다."));
        }

        // 회원가입용 SIGN_UP은 존재 여부 체크하지 않음 (새 계정)

        String code = String.format("%0" + CODE_LENGTH + "d", new Random().nextInt(999_999));
        String key = purpose.name() + ":" + email;
        redisTemplate.opsForValue().set(key, code, Duration.ofMinutes(CODE_TTL_MINUTES));

        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom("gradisupport@naver.com");
            helper.setTo(email);

            String subject = switch (purpose) {
                case FIND_ACCOUNT -> "[Gradi] 아이디 찾기 인증번호";
                case RESET_PASSWORD -> "[Gradi] 비밀번호 재설정 인증번호";
                case SIGN_UP -> "[Gradi] 회원가입 이메일 인증번호";
            };

            String text = "인증번호는 " + code + " 입니다. " + CODE_TTL_MINUTES + "분 이내에 입력해주세요.";

            helper.setSubject(subject);
            helper.setText(text, true);

            mailSender.send(message);
        } catch (MessagingException e) {
            throw new RuntimeException("이메일 전송 실패", e);
        }
    }



    public VerifyCodeResponse<FindResponseDto> verifyCode(FindRequestDto request, VerificationPurpose purpose) {
        String key = purpose.name() + ":" + request.getEmail();
        String savedCode = redisTemplate.opsForValue().get(key);

        if (savedCode == null || !savedCode.equals(request.getCode())) {
            return new VerifyCodeResponse<>(false, null);
        }

        // 회원가입일 경우 인증번호 확인만
        if (purpose == VerificationPurpose.SIGN_UP) {
            redisTemplate.delete(key);
            return new VerifyCodeResponse<>(true, null);
        }

        // 이미 가입된 사용자 대상 검증
        Optional<User> userOptional = userRepository.findByEmail(request.getEmail());
        if (userOptional.isPresent()) {
            User user = userOptional.get();
            redisTemplate.delete(key);

            String token = null;
            if (purpose == VerificationPurpose.RESET_PASSWORD) {
                token = jwtTokenProvider.generateResetPasswordToken(request.getEmail());
            }

            FindResponseDto dto = UserMapper.toFindResponseDto(user, purpose, token);
            return new VerifyCodeResponse<>(true, dto);
        } else {
            throw new IllegalArgumentException("해당 이메일의 사용자가 존재하지 않습니다.");
        }
    }






}





