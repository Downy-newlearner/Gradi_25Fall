package kr.ac.dankook.microservices.notification.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class WebClientConfig {

    @Value("${grading.service.url}")
    private String gradingBaseUrl;

    @Value("${academy.service.url}")
    private String academyBaseUrl;


    @Bean
    public WebClient academyServiceWebClient() {
        return WebClient.builder()
                .baseUrl(academyBaseUrl)
                .build();
    }

    @Bean
    public WebClient gradingServiceWebClient() {
        return WebClient.builder()
                .baseUrl(gradingBaseUrl)
                .build();
    }
}
