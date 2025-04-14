package com.ssfinder.global.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import javax.annotation.PostConstruct;
import java.io.IOException;

/**
 * packageName    : com.ssfinder.global.config<br>
 * fileName       : FirebaseConfig.java<br>
 * author         : okeio<br>
 * date           : 2025-03-24<br>
 * description    : Firebase Admin SDK 초기화를 담당하는 설정 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio           최초생성<br>
 * <br>
 */
@Configuration
@Slf4j
public class FirebaseConfig {

    /**
     * Firebase 서비스 계정 JSON 파일 경로
     */
    @Value("${fcm.firebase-config-path}")
    private String firebaseConfigPath;

    /**
     * FirebaseApp 초기화 메서드
     *
     * <p>Spring 컨텍스트가 시작되면 {@code @PostConstruct} 어노테이션을 통해 호출됩니다.
     * 서비스 계정 파일을 기반으로 Firebase 인증을 설정하며,
     * FirebaseApp이 이미 초기화된 경우 중복 초기화를 방지합니다.</p>
     */
    @PostConstruct
    public void init() {
        try {
            ClassPathResource serviceAccount = new ClassPathResource("/firebase/serviceAccountKey.json");

            FirebaseOptions options = new FirebaseOptions.Builder()
                    .setCredentials(GoogleCredentials.fromStream(serviceAccount.getInputStream()))
                    .build();
            FirebaseApp.initializeApp(options);

            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
            }
        } catch (IOException e) {
            log.error(e.getMessage());
        }
    }
}
