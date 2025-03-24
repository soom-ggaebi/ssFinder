package com.ssfinder.domain.notification.service;

import com.ssfinder.domain.user.service.UserService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

/**
 * packageName    : com.ssfinder.domain.notification.service<br>
 * fileName       : NotificationService.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class NotificationService {
    private final FcmTokenService fcmTokenService;
    private final UserService userService;

    // 3. 물건 매칭 알림

    // 4. 소지품 챙기라는 안내 알림 (API 엔드포인트 구현)
    public void sendItemReminderNotification(Integer userId, String itemName) {

    }
}
