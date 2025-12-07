package kr.ac.dankook.microservices.user;

import kr.ac.dankook.microservices.user.config.SecurityConfig;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Import;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;


@EnableJpaAuditing
@SpringBootApplication(scanBasePackages = {
        "kr.ac.dankook.microservices.user",   // user-service 패키지
        "kr.ac.dankook.microservices.common"  // common-library 패키지
})
public class UserServiceApplication {

    public static void main(String[] args) {
        SpringApplication.run(UserServiceApplication.class, args);
    }

}
