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
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio           최초생성<br>
 * <br>
 */
@Configuration
@Slf4j
public class FirebaseConfig {
    @Value("${fcm.firebase-config-path}")
    private String firebaseConfigPath;

    @PostConstruct
    public void init() {
        try {
            GoogleCredentials googleCredentials = GoogleCredentials
                    .fromStream(new ClassPathResource(firebaseConfigPath).getInputStream());
            FirebaseOptions options = new FirebaseOptions.Builder()
                    .setCredentials(googleCredentials)
                    .build();
            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseApp.initializeApp(options);
            }
        } catch (IOException e) {
            log.error(e.getMessage());
        }
    }
}
