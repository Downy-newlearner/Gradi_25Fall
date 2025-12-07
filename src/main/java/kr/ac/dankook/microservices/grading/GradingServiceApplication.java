package kr.ac.dankook.microservices.grading;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.scheduling.annotation.EnableAsync;


@EnableAsync
@EnableJpaAuditing
@SpringBootApplication(scanBasePackages = {
        "kr.ac.dankook.microservices.grading",
        "kr.ac.dankook.microservices.common"
})
public class GradingServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(GradingServiceApplication.class, args);
    }

}
