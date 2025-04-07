package com.ssfinder.domain.notification.service;

import com.ssfinder.domain.chat.dto.kafka.KafkaChatMessage;
import com.ssfinder.domain.chat.entity.MessageType;
import com.ssfinder.domain.chat.service.ChatRoomService;
import com.ssfinder.domain.chat.service.ChatService;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.service.FoundItemService;
import com.ssfinder.domain.lostitem.entity.LostItem;
import com.ssfinder.domain.lostitem.service.LostItemService;
import com.ssfinder.domain.notification.dto.request.AiMatchNotificationRequest;
import com.ssfinder.domain.notification.entity.NotificationType;
import com.ssfinder.domain.notification.entity.WeatherCondition;
import com.ssfinder.domain.notification.event.NotificationHistoryEvent;
import com.ssfinder.domain.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
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
 * 2025-04-02          okeio          알림 이력 관리를 위한 EventPublisher 추가<br>
 * 2025-04-06          okeio          메세지 타입에 따른 채팅 알림 메세지 변경<br>
 * 2025-04-07          okeio          리팩토링<br>
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
    private final ChatService chatService;
    private final ChatRoomService chatRoomService;
    private final LostItemService lostItemService;
    private final ApplicationEventPublisher eventPublisher;

    private final static String NOTIFICATION_TITLE = "숨숨파인더";
    private final static String CHAT_PLACEHOLDER_IMAGE_MESSAGE = "사진을 보냈습니다.";
    private final static String CHAT_PLACEHOLDER_LOCATION_MESSAGE = "위치를 공유했습니다.";
    private final static String AI_MATCH_PLACEHOLDER_MESSAGE = "찾고 계신 물건과 비슷한 습득물이 등록되었습니다!";

    // 1. 습득물 게시글 최초 등록일로부터 6일차, 7일차 알림
    @Scheduled(cron = "0 0 10 * * *")
    @Transactional(readOnly = true)
    public void sendFoundItemReminders() {
        log.info("[알림] 습득물 게시글 알림 스케쥴링 시작");

        // 6일차 알림 대상 조회
        processFoundItemNotifications(6, "등록하신 습득물 게시글 '%s'이 내일이면 7일이 됩니다.");
        log.info("[알림] 습득물 게시글 6일차 알림 스케쥴링 완료");

        // 7일차 알림 대상 조회
        processFoundItemNotifications(7, "등록하신 습득물 게시글 '%s'이 오늘로 7일이 되었습니다.");
        log.info("[알림] 습득물 게시글 7일차 알림 스케쥴링 완료");
    }

    private void processFoundItemNotifications(int days, String messageTemplate) {
        List<FoundItem> items = foundItemService.getStoredItemsFoundDaysAgo(days);
        log.info("[알림] {}일차 Found items: {}", days, items.size());

        for (FoundItem item : items) {
            Integer userId = item.getUser().getId();

            // 알림 설정 확인
            if (!userNotificationSettingService.isNotificationEnabledFor(userId, NotificationType.TRANSFER))
                continue;

            List<String> tokens = fcmTokenService.getFcmTokens(userId);

            String notificationContent = String.format(messageTemplate, item.getName());

            Map<String, String> data = new HashMap<>();
            data.put("type", NotificationType.TRANSFER.name());
            data.put("itemId", String.valueOf(item.getId()));

            boolean notificationSent = fcmMessageService.sendNotificationToDevices(
                    tokens,
                    NOTIFICATION_TITLE,
                    notificationContent,
                    data
            );

            if (notificationSent) {
                eventPublisher.publishEvent(new NotificationHistoryEvent(
                        this, userId, NOTIFICATION_TITLE, notificationContent, NotificationType.TRANSFER
                ));
            }
        }
    }

    // 2. 채팅 알림
    public void sendChatNotification(KafkaChatMessage kafkaChatMessage) {
        User opponentUser = chatService.getOpponentUser(kafkaChatMessage.chatRoomId(), kafkaChatMessage.senderId());
        int userId = opponentUser.getId();

        // 알림 설정 확인
        if (!userNotificationSettingService.isNotificationEnabledFor(userId, NotificationType.CHAT) ||
                !chatRoomService.getChatRoomParticipant(kafkaChatMessage.chatRoomId(), userId).getNotificationEnabled())
            return;

        List<String> tokens = fcmTokenService.getFcmTokens(userId);

        // 메시지 타입 분류
        MessageType messageType = kafkaChatMessage.type();
        String content = kafkaChatMessage.content();

        if (messageType.equals(MessageType.IMAGE)) {
            content = CHAT_PLACEHOLDER_IMAGE_MESSAGE;

        } else if (messageType.equals(MessageType.LOCATION)) {
            content = CHAT_PLACEHOLDER_LOCATION_MESSAGE;
        } else if (messageType.equals(MessageType.NORMAL)) {
            content = kafkaChatMessage.nickname() + "님의 메시지";
        }

        boolean notificationSent = fcmMessageService.sendNotificationToDevices(
                tokens,
                NOTIFICATION_TITLE,
                content,
                kafkaChatMessage.toChatNotificationMap()
        );

        if (notificationSent) {
            eventPublisher.publishEvent(new NotificationHistoryEvent
                    (this, userId, NOTIFICATION_TITLE, content, NotificationType.CHAT));
        }
    }

    // 3. 습득물 게시된 경우 분실자에게 AI 매칭 알림
    public void sendItemMatchingNotifications(List<AiMatchNotificationRequest> aiMatchNotificationRequests) {
        List<AiMatchNotificationRequest> enabledNotifications = aiMatchNotificationRequests.stream()
                .filter(request -> {
                    LostItem lostItem = lostItemService.findLostItemById(request.lostItemId());
                    return lostItem.getNotificationEnabled();
                })
                .toList();

        for (AiMatchNotificationRequest request : enabledNotifications) {
            LostItem lostItem = lostItemService.findLostItemById(request.lostItemId());
            Integer userId = lostItem.getUser().getId();
            List<String> tokens = fcmTokenService.getFcmTokens(userId);

            if (tokens.isEmpty()) {
                continue;
            }

            boolean notificationSent = fcmMessageService.sendNotificationToDevices(
                    tokens,
                    NOTIFICATION_TITLE,
                    AI_MATCH_PLACEHOLDER_MESSAGE,
                    request.toAiMatchNotificationMap()
            );

            if (notificationSent) {
                eventPublisher.publishEvent(new NotificationHistoryEvent(
                        this,
                        userId,
                        NOTIFICATION_TITLE,
                        AI_MATCH_PLACEHOLDER_MESSAGE,
                        NotificationType.AI_MATCH
                ));
            }
        }
    }

    // 4. 소지품 알림
    public void sendItemReminderNotification(Integer userId, WeatherCondition weatherCondition) {
        if (!userNotificationSettingService.isNotificationEnabledFor(userId, NotificationType.ITEM_REMINDER))
            return;

        List<String> tokens = fcmTokenService.getFcmTokens(userId);

        Map<String, String> data = new HashMap<>();
        data.put("type", NotificationType.ITEM_REMINDER.name());

        boolean notificationSent = fcmMessageService.sendNotificationToDevices(
                tokens,
                NOTIFICATION_TITLE,
                weatherCondition.getNotificationContent(),
                data
        );

        if (notificationSent) {
            eventPublisher.publishEvent(
                    new NotificationHistoryEvent(this, userId, NOTIFICATION_TITLE,
                            weatherCondition.getNotificationContent(), NotificationType.ITEM_REMINDER));
        }
    }
}
