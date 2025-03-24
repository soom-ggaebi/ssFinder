package com.ssfinder.domain.notification.service;

import com.google.firebase.messaging.*;
import com.ssfinder.domain.notification.dto.request.FcmTokenRequest;
import com.ssfinder.domain.notification.entity.FcmToken;
import com.ssfinder.domain.notification.repository.FcmTokenRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ExecutionException;

/**
 * packageName    : com.ssfinder.domain.notification.service<br>
 * fileName       : FcmTokenService.java<br>
 * author         : okeio<br>
 * date           : 2025-03-24<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio           최초생성<br>
 * <br>
 */

@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class FcmTokenService {
    private final FcmTokenRepository fcmTokenRepository;
    private final UserService userService;

    public void registerFcmToken(int userId, FcmTokenRequest fcmTokenRequest) {
        User user = userService.findUserById(userId);
        String token = fcmTokenRequest.token();

        Optional<FcmToken> fcmTokenOpt = fcmTokenRepository.findByUserAndFcmToken(user, token);

        if (fcmTokenOpt.isPresent()) {
            fcmTokenOpt.get().setUpdatedAt(LocalDateTime.now());
        } else {
            fcmTokenRepository.save(new FcmToken(token, user));
        }
    }

    public void deleteFcmToken(int userId, FcmTokenRequest fcmTokenRequest) {
        User user = userService.findUserById(userId);
        String token = fcmTokenRequest.token();

        Optional<FcmToken> fcmTokenOpt = fcmTokenRepository.findByUserAndFcmToken(user, token);

        fcmTokenOpt.ifPresent(fcmTokenRepository::delete);
    }

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

    // 여러 사용자에게 동일한 알림 전송
    public void sendNotificationToUsers(List<String> tokens, String title, String body, Map<String, String> data) {
        MulticastMessage message = MulticastMessage.builder()
                .setNotification(Notification.builder()
                        .setTitle(title)
                        .setBody(body)
                        .build())
                .putAllData(data)
                .addAllTokens(tokens)
                .build();

        try {
            BatchResponse response = FirebaseMessaging.getInstance().sendMulticastAsync(message).get();
            log.info("알림 전송 성공: {} / {}", response.getSuccessCount(), tokens.size());
        } catch (InterruptedException | ExecutionException e) {
            log.error("알림 전송 실패: {}", e.getMessage());
        }
    }
}
