package com.ssfinder.domain.notification.service;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.service.FoundItemService;
import com.ssfinder.domain.notification.entity.NotificationType;
import com.ssfinder.domain.notification.entity.WeatherCondition;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * packageName    : com.ssfinder.domain.notification.service<br>
 * fileName       : NotificationService.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    : 종류별 알림에 대한 Service 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio          최초생성<br>
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class NotificationService {
    private final FcmTokenService fcmTokenService;
    private final FcmMessageService fcmMessageService;
    private final FoundItemService foundItemService;
    private final UserNotificationSettingService userNotificationSettingService;

    // 1. 습득물 게시글 최초 등록일로부터 6일차, 7일차 알림
    @Scheduled(cron = "0 0 10 * * *")
    @Transactional(readOnly = true)
    public void sendFoundItemReminders() {
        log.info("[알림] 습득물 게시글 알림 스케쥴링 시작");
        // 6일차 알림 대상 조회
        List<FoundItem> sixDayItems = foundItemService.getStoredItemsFoundDaysAgo(6);
        log.info("6일차 Found items: {}", sixDayItems);
        for (FoundItem item : sixDayItems) {
            Integer userId = item.getUser().getId();

            // 알림 설정 확인
            if (userNotificationSettingService.isNotificationDisabledFor(userId, NotificationType.TRANSFER))
                continue;

            List<String> tokens = fcmTokenService.getFcmTokens(userId);
            if (!tokens.isEmpty()) {
                Map<String, String> data = new HashMap<>();
                data.put("type", NotificationType.TRANSFER.name());
                data.put("itemId", item.getId().toString());

                fcmMessageService.sendNotificationToUsers(
                        tokens,
                        "습득물 알림",
                        "등록하신 습득물 게시글 '" + item.getName() + "'이 내일이면 7일이 됩니다.",
                        data
                );
            }
        }

        log.info("[알림] 습득물 게시글 6일차 알림 스케쥴링 완료");

        // 7일차 알림 대상 조회
        List<FoundItem> sevenDayItems = foundItemService.getStoredItemsFoundDaysAgo(7);
        log.info("7일차 Found items: {}", sevenDayItems);

        for (FoundItem item : sevenDayItems) {
            Integer userId = item.getUser().getId();

            // 알림 설정 확인
            if (userNotificationSettingService.isNotificationDisabledFor(userId, NotificationType.TRANSFER))
                continue;

            List<String> tokens = fcmTokenService.getFcmTokens(userId);
            if (!tokens.isEmpty()) {
                Map<String, String> data = new HashMap<>();
                data.put("type", NotificationType.TRANSFER.name());
                data.put("itemId", item.getId().toString());

                fcmMessageService.sendNotificationToUsers(
                        tokens,
                        "습득물 알림",
                        "등록하신 습득물 게시글 '" + item.getName() + "'이 오늘로 7일이 되었습니다.",
                        data
                );
            }
        }

        log.info("[알림] 습득물 게시글 7일차 알림 스케쥴링 완료");
    }

    // 2. 채팅 알림
    // TODO 채팅 로직에서 채팅 DB 저장 시 트리거
    public void sendChatNotification(Integer userId, String senderName, String message) {
        // 알림 설정 확인
        if (userNotificationSettingService.isNotificationDisabledFor(userId, NotificationType.CHAT))
            return;

        List<String> tokens = fcmTokenService.getFcmTokens(userId);
        if (!tokens.isEmpty()) {
            Map<String, String> data = new HashMap<>();
            data.put("type", NotificationType.CHAT.name());
            data.put("senderName", senderName);

            fcmMessageService.sendNotificationToUsers(
                    tokens,
                    senderName + "님의 메시지",
                    message,
                    data
            );
        }
    }

    // 3. 물건 매칭 알림
    @Transactional(readOnly = true)
    public void sendItemMatchingNotifications() {
        // TODO: AI 기능 완성 시, 매칭된 회원 목록 조회
        //List<User> usersWithNewMatches;

//        for (User user : usersWithNewMatches) {
//            List<String> tokens = fcmTokenService.getFcmTokens(user.getId());
//            if (!tokens.isEmpty()) {
//                Map<String, String> data = new HashMap<>();
//                data.put("type", NotificationType.AI_MATCH.toString());
//
//                fcmService.sendNotificationToUsers(
//                        tokens,
//                        "새로운 매칭 물건 알림",
//                        "찾고 계신 물건과 일치하는 습득물이 등록되었습니다!",
//                        data
//                );
//            }
//        }
    }

    // 4. 소지품 알림
    public void sendItemReminderNotification(Integer userId, WeatherCondition weatherCondition) {
        if (userNotificationSettingService.isNotificationDisabledFor(userId, NotificationType.ITEM_REMINDER))
            return;

        List<String> tokens = fcmTokenService.getFcmTokens(userId);
        if (!tokens.isEmpty()) {
            Map<String, String> data = new HashMap<>();
            data.put("type", NotificationType.ITEM_REMINDER.name());

            fcmMessageService.sendNotificationToUsers(
                    tokens,
                    "숨숨 파인더",
                    weatherCondition.getNotificationContent(),
                    data
            );
        }
    }
}
