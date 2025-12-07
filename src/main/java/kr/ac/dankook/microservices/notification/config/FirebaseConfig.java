package kr.ac.dankook.microservices.notification.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;

import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    @PostConstruct
    public void initializeFirebase() throws IOException {
        if (FirebaseApp.getApps().isEmpty()) {
            try (InputStream serviceAccount =
                         getClass().getResourceAsStream("/firebase/gradi-bd52c-firebase-adminsdk-fbsvc-a3bd8532d3.json")) {

                if (serviceAccount == null) {
                    throw new IllegalStateException("Firebase 서비스 계정 키 파일을 찾을 수 없습니다.");
                }

                FirebaseOptions options = FirebaseOptions.builder()
                        .setCredentials(GoogleCredentials.fromStream(serviceAccount))
                        .build();

                FirebaseApp.initializeApp(options);
                System.out.println("✅ Firebase Admin SDK 초기화 완료 (개발용)");
            }
        }
    }
}
