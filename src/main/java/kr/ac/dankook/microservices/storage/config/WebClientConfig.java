package kr.ac.dankook.microservices.storage.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class WebClientConfig {

    @Value("${grading.service.url}")
    private String gradingBaseUrl;
    @Bean
    public WebClient gradingWebClient() {
        return WebClient.builder()
                .baseUrl(gradingBaseUrl)
                .build();
    }
}
