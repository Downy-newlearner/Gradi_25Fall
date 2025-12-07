package kr.ac.dankook.microservices.grading.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

@Slf4j
@Service
@RequiredArgsConstructor
public class WebClientService {

    private final WebClient fastApiServiceWebClient;  // Bean으로 주입

    public String explanationPost(String uri, Object payload) {
        try {
            return fastApiServiceWebClient.post()
                    .uri(uri)
                    .bodyValue(payload)
                    .retrieve()
                    .bodyToMono(String.class)
                    .onErrorReturn("(정보 없음)")
                    .block();
        } catch (Exception e) {
            log.warn("❗ fastApiService lookup failed: {}", uri, e);
            return "(정보 없음)";
        }



}
}
