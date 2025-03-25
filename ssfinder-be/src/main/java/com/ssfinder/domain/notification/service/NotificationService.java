package com.ssfinder.domain.notification.service;

import com.ssfinder.domain.found.entity.FoundItem;
import com.ssfinder.domain.found.service.FoundService;
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
 * description    :  <br>
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
    private final FoundService foundService;

    // 1. 습득물 게시글 최초 등록일로부터 6일차, 7일차 알림
    @Scheduled(cron = "0 0 10 * * *")
    @Transactional(readOnly = true)
    public void sendLostItemReminders() {
        // 6일차 알림 대상 조회
        List<FoundItem> sixDayItems = foundService.getStoredItemsFoundDaysAgo(6);

        for (FoundItem item : sixDayItems) {
            List<String> tokens = fcmTokenService.getFcmTokens(item.getUser().getId());
            if (!tokens.isEmpty()) {
                Map<String, String> data = new HashMap<>();
                data.put("type", "FOUND_ITEM_REMINDER");
                data.put("itemId", item.getId().toString());

                fcmMessageService.sendNotificationToUsers(
                        tokens,
                        "습득물 알림",
                        "등록하신 습득물 게시글 '" + item.getName() + "'이 내일이면 7일이 됩니다.",
                        data
                );
            }
        }

        // 7일차 알림 대상 조회
        List<FoundItem> sevenDayItems = foundService.getStoredItemsFoundDaysAgo(7);
        for (FoundItem item : sevenDayItems) {
            List<String> tokens = fcmTokenService.getFcmTokens(item.getUser().getId());
            if (!tokens.isEmpty()) {
                Map<String, String> data = new HashMap<>();
                data.put("type", "FOUND_ITEM_REMINDER");
                data.put("itemId", item.getId().toString());

                fcmMessageService.sendNotificationToUsers(
                        tokens,
                        "습득물 알림",
                        "등록하신 습득물 게시글 '" + item.getName() + "'이 오늘로 7일이 되었습니다.",
                        data
                );
            }
        }
    }

    // 2. 채팅 알림
    public void sendChatNotification(Integer userId, String senderName, String message) {
        List<String> tokens = fcmTokenService.getFcmTokens(userId);
        if (!tokens.isEmpty()) {
            Map<String, String> data = new HashMap<>();
            data.put("type", "CHAT");
            data.put("senderId", senderName);

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
//                data.put("type", "ITEM_MATCHING");
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
    public void sendItemReminderNotification(Integer userId, String itemName) {
        List<String> tokens = fcmTokenService.getFcmTokens(userId);
        if (!tokens.isEmpty()) {
            Map<String, String> data = new HashMap<>();
            data.put("type", "ITEM_REMINDER");
            data.put("itemName", itemName);

            fcmMessageService.sendNotificationToUsers(
                    tokens,
                    "소지품 알림",
                    itemName + "을(를) 챙기세요!",
                    data
            );
        }
    }
}
