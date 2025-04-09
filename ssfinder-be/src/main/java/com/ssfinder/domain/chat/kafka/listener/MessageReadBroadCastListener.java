package com.ssfinder.domain.chat.kafka.listener;

import com.ssfinder.domain.chat.dto.kafka.KafkaChatReadMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

/**
 * packageName    : com.ssfinder.domain.chat.kafka.listener<br>
 * fileName       : MessageReadBroadCastListener.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-05<br>
 * description    : 읽음 브로드스트 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-05          nature1216          최초생성<br>
 * <br>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MessageReadBroadCastListener {

    private final SimpMessagingTemplate template;

    @KafkaListener(topics = "${kafka.topic.chat-read}", groupId = "chat-message-read-broadcast-temp", containerFactory = "chatMessageReadListenerContainerFactory")
    public void listen(KafkaChatReadMessage message) {
        log.info("[MESSAGE READ] read broadcast: chatRoomId {}", message.chatRoomId());
        log.info("message: {}", message);

        template.convertAndSend("/sub/chat-room/" + message.chatRoomId() + "/read", message);
    }
}
