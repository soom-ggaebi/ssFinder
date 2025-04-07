package com.ssfinder.domain.chat.kafka.listener;

import com.ssfinder.domain.chat.dto.kafka.KafkaChatMessage;
import com.ssfinder.domain.notification.service.NotificationService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

/**
 * packageName    : com.ssfinder.domain.chat.kafka.listener<br>
 * fileName       : MessageBroadcastListener.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-03<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-03          nature1216          최초생성<br>
 * 2025-04-06          okeio               알림 발송 로직 추가<br>
 * <br>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MessageBroadcastListener {
    private final SimpMessagingTemplate template;
    private final NotificationService notificationService;


    @KafkaListener(topics = "${kafka.topic.chat-message-sent}", groupId = "chat-message-broadcast", containerFactory = "chatMessageListenerContainerFactory")
    public void listen(KafkaChatMessage message) {
        log.info("message is sent to /sub/chat-room/" + message.chatRoomId());
        log.info("message: {}", message);

        template.convertAndSend("/sub/chat-room/" + message.chatRoomId(), message);

        try {
            notificationService.sendChatNotification(message);
        } catch (Exception e) {
            log.error("[채팅 알림 전송 실패]", e);
        }
    }
}
