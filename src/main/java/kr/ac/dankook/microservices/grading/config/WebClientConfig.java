package kr.ac.dankook.microservices.grading.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.reactive.function.client.WebClient;

@Configuration
public class WebClientConfig {


    @Value("${fastApi.service.url}")
    private String fastApiBaseUrl;


    @Bean
    public WebClient fastApiServiceWebClient() {
        return WebClient.builder()
                .baseUrl(fastApiBaseUrl)
                .build();
    }

}
