package com.ssfinder.domain.notification.service;

import com.google.firebase.messaging.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.Objects;

/**
 * packageName    : com.ssfinder.domain.notification.service<br>
 * fileName       : FcmMessageService.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    : Firebase Cloud Messaging을 통해 단일 또는 다중 디바이스에 알림을 전송하는 서비스입니다.<br>
 *                  유효하지 않은 FCM 토큰이 발견되면 자동으로 삭제 처리합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * 2025-04-04          okeio           알림 요청 시, 유효하지 않은 토큰인 경우 토큰 삭제<br>
 * <br>
 */
@Slf4j
@Service
public class FcmMessageService {

    private final FcmTokenService fcmTokenService;

    public FcmMessageService(FcmTokenService fcmTokenService) {
        this.fcmTokenService = fcmTokenService;
    }

    /**
     * 단일 디바이스에 알림을 전송합니다.
     *
     * <p>
     * 알림 전송 실패 시, 유효하지 않은 FCM 토큰은 삭제 처리됩니다.
     * </p>
     *
     * @param token 대상 디바이스의 FCM 토큰
     * @param title 알림 제목
     * @param body 알림 본문
     * @param data 알림과 함께 전달할 데이터(Map 형태)
     * @return 전송 성공 여부
     */
    public boolean sendNotificationToDevice(String token, String title, String body, Map<String, String> data) {
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
            String response = FirebaseMessaging.getInstance().send(message);
            log.info("알림 전송 성공: {}", response);
            return true;
        } catch (FirebaseMessagingException e) {
            MessagingErrorCode errorCode = e.getMessagingErrorCode();
            if (errorCode.equals(MessagingErrorCode.UNREGISTERED) || errorCode.equals(MessagingErrorCode.INVALID_ARGUMENT)) {
                log.info("알림 전송 실패: 유효한 토큰이 아닙니다. - {}", e.getMessage());
                fcmTokenService.deleteFcmToken(token);
            }
            else if (errorCode.equals(MessagingErrorCode.INTERNAL) || errorCode.equals(MessagingErrorCode.UNAVAILABLE)) {
                log.info("알림 전송 실패: FCM 서버 에러 - {}", e.getMessage());
            }
            return false;
        }
    }

    /**
     * 여러 디바이스에 알림을 전송합니다.
     *
     * <p>
     * 유효한 토큰이 하나라도 존재하여 전송에 성공하면 true를 반환합니다.
     * 각 토큰에 대해 개별적으로 전송하며, 유효하지 않은 토큰은 삭제됩니다.
     * </p>
     *
     * @param tokens 대상 디바이스의 FCM 토큰 리스트
     * @param title 알림 제목
     * @param body 알림 본문
     * @param data 알림과 함께 전달할 데이터(Map 형태)
     * @return 하나 이상의 디바이스에 성공적으로 전송되었는지 여부
     */
    public boolean sendNotificationToDevices(List<String> tokens, String title, String body, Map<String, String> data) {
        if (Objects.isNull(tokens) || tokens.isEmpty()) {
            return false;
        }

        boolean anySuccess = false;
        for (String token : tokens) {
            if (Objects.nonNull(token) && !token.isBlank() && sendNotificationToDevice(token, title, body, data)) {
                anySuccess = true;
            }
        }
        return anySuccess;
    }
}
