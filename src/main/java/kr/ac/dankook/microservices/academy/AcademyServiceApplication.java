package kr.ac.dankook.microservices.academy;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;

@EnableJpaAuditing
@SpringBootApplication(scanBasePackages = {
        "kr.ac.dankook.microservices.academy",
        "kr.ac.dankook.microservices.common"
})
public class AcademyServiceApplication {
    public static void main(String[] args) {
        SpringApplication.run(AcademyServiceApplication.class, args);
    }

}
