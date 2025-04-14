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
 * description    : 종류별 알림 전송 로직을 처리하는 서비스 클래스입니다.<br>
 *                  습득물 알림, 채팅 알림, AI 매칭 알림, 소지품 리마인더 알림 등을 지원합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * 2025-04-02          okeio           알림 이력 관리를 위한 EventPublisher 추가<br>
 * 2025-04-06          okeio           메세지 타입에 따른 채팅 알림 메세지 변경<br>
 * 2025-04-07          okeio           리팩토링<br>
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

    /**
     * 습득물 게시글 등록일 기준으로 6일차, 7일차에 해당하는 사용자에게 리마인더 알림을 전송합니다.
     * <p>매일 오전 10시에 스케줄링되어 실행됩니다.</p>
     */
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

    /**
     * 특정 일 수가 지난 습득물에 대해 알림 메시지를 전송하고, 이력을 저장합니다.
     *
     * @param days 기준 일 수 (예: 6 또는 7)
     * @param messageTemplate 알림 메시지 템플릿
     */
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

    /**
     * 채팅 메시지가 도착했을 때 상대방에게 알림을 전송합니다.
     * <p>메시지 유형에 따라 다른 본문 내용을 생성하고, 수신자 설정 여부와 상태를 확인합니다.</p>
     *
     * @param kafkaChatMessage Kafka에서 전달받은 채팅 메시지 객체
     */
    public void sendChatNotification(KafkaChatMessage kafkaChatMessage) {
        int chatRoomId = kafkaChatMessage.chatRoomId();
        User opponentUser = chatService.getOpponentUser(kafkaChatMessage.senderId(), chatRoomId);
        int userId = opponentUser.getId();

        // 알림 설정 확인
        if (!userNotificationSettingService.isNotificationEnabledFor(userId, NotificationType.CHAT) ||
                !chatRoomService.getChatRoomParticipant(chatRoomId, userId).getNotificationEnabled() ||
                chatService.isViewingChatRoom(userId, chatRoomId))
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

    /**
     * AI 매칭된 습득물에 대해 분실자에게 알림을 전송합니다.
     * <p>사용자의 알림 설정과 분실물 알림 허용 여부를 기반으로 전송됩니다.</p>
     *
     * @param aiMatchNotificationRequests 매칭된 알림 요청 목록
     */
    // TODO 쿼리 중복 호출 개선
    public void sendItemMatchingNotifications(List<AiMatchNotificationRequest> aiMatchNotificationRequests) {
        List<AiMatchNotificationRequest> enabledNotifications = aiMatchNotificationRequests.stream()
                .filter(request -> {
                    LostItem lostItem = lostItemService.findLostItemById(request.lostItemId());
                    Integer userId = lostItem.getUser().getId();
                    return userNotificationSettingService.isNotificationEnabledFor(userId, NotificationType.AI_MATCH)
                            && lostItem.getNotificationEnabled();
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

    /**
     * 날씨 정보에 기반하여 소지품 리마인더 알림을 전송합니다.
     *
     * @param userId 알림 수신 대상 사용자 ID
     * @param weatherCondition 날씨 조건에 따른 알림 메시지 콘텐츠
     */
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
