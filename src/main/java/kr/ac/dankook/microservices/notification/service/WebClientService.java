package kr.ac.dankook.microservices.notification.service;

import kr.ac.dankook.microservices.common.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Slf4j
@Service
@RequiredArgsConstructor
public class WebClientService {

    private final WebClient academyServiceWebClient;  // Bean으로 주입
    private final WebClient gradingServiceWebClient;  // Bean으로 주입
    private final JwtTokenProvider jwtTokenProvider;

    // ========= Academy-safe-get =========
    public String academySafeGet(String uri, Object... uriVars) {
        try {

            String internalToken = jwtTokenProvider.generateInternalToken();

            return academyServiceWebClient.get()
                    .uri(uri, uriVars)
                    .header("Authorization", "Bearer " + internalToken)
                    .retrieve()
                    .bodyToMono(String.class)
                    .onErrorReturn("(정보 없음)")
                    .block();
        } catch (Exception e) {
            log.warn("❗ academy-service lookup failed: {}", uri);
            return "(정보 없음)";
        }
    }

    // ========= Grading-safe-get =========
    public String gradingSafeGet(String uri, Object... uriVars) {
        try {
            String internalToken = jwtTokenProvider.generateInternalToken();

            return gradingServiceWebClient.get()
                    .uri(uri, uriVars)
                    .header("Authorization", "Bearer " + internalToken)
                    .retrieve()
                    .bodyToMono(String.class)
                    .onErrorReturn("(정보 없음)")
                    .block();
        } catch (Exception e) {
            log.warn("❗ grading-service lookup failed: {}", uri);
            return "(정보 없음)";
        }
    }


    }




