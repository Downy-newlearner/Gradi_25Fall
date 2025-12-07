package kr.ac.dankook.microservices.user.service;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import kr.ac.dankook.microservices.common.security.JwtTokenProvider;
import kr.ac.dankook.microservices.common.service.TokenService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

@Slf4j
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtTokenProvider jwtTokenProvider;
    private final TokenService tokenService;

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        String requestURI = request.getRequestURI();
        log.info("Request URI: {}", requestURI);

        // 공개 API는 필터 통과
        if (isPublicURI(requestURI)) {
            filterChain.doFilter(request, response);
            return;
        }

        String token = resolveToken(request);

        if (token != null) {
            // 토큰 유효성 확인
            if (!jwtTokenProvider.validateToken(token)) {
                handleUnauthorizedResponse(response, "Invalid JWT Token");
                return;
            }

            // 블랙리스트 확인
            if (tokenService.isTokenBlacklisted(token)) {
                handleUnauthorizedResponse(response, "Token is blacklisted");
                return;
            }

            // 인증 객체 가져오기
            Authentication authentication = jwtTokenProvider.getAuthentication(token);

            if (authentication != null) {
                SecurityContextHolder.getContext().setAuthentication(authentication);
            } else {
                handleUnauthorizedResponse(response, "Invalid JWT Token");
                return;
            }
        } else {
            handleUnauthorizedResponse(response, "JWT token is missing");
            return;
        }

        filterChain.doFilter(request, response);
    }

    // Authorization 헤더에서 Bearer 토큰 추출
    private String resolveToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (bearerToken != null && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7).trim();
        }
        return null;
    }

    // 공개 API 목록
    private boolean isPublicURI(String uri) {
        return uri.startsWith("/sign-in")
                || uri.startsWith("/sign-up")
                || uri.startsWith("/send-code/")
                || uri.startsWith("/users/")
                || uri.startsWith("/verify")
                || uri.startsWith("/reset-request")
                || uri.startsWith("/reset-password")
                || uri.startsWith("/error");
    }

    // 401 Unauthorized JSON 응답
    private void handleUnauthorizedResponse(HttpServletResponse response, String message) throws IOException {
        response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.getWriter().write("{\"error\": \"" + message + "\"}");
        response.getWriter().flush();
    }
}
