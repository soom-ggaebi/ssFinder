package com.ssfinder.domain.notification.service;

import com.google.firebase.messaging.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.ExecutionException;

/**
 * packageName    : com.ssfinder.domain.notification.service<br>
 * fileName       : FcmMessageService.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    : Firebase에 알림을 요청하는 서비스 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * <br>
 */
@Slf4j
@Service
public class FcmMessageService {

    public void sendNotificationToUser(String token, String title, String body, Map<String, String> data) {
        Message message = Message.builder()
                .setNotification(Notification
                        .builder()
                        .setTitle(title)
                        .setBody(body)
                        .build())
                .putAllData(data)
                .setToken(token)
                .build();

        try {
            String response = FirebaseMessaging.getInstance().sendAsync(message).get();
            log.info("알림 전송 성공: {}", response);
        } catch (InterruptedException | ExecutionException e) {
            log.error("알림 전송 성공: {}", e.getMessage());
        }
    }

    public void sendNotificationToUsers(List<String> tokens, String title, String body, Map<String, String> data) {
        if (Objects.isNull(tokens) || tokens.isEmpty()) {
            return;
        }

        for (String token : tokens) {
            sendNotificationToUser(token, title, body, data);
        }
    }
}
