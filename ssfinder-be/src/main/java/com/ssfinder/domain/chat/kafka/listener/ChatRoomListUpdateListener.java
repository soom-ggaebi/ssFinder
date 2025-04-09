package com.ssfinder.domain.chat.kafka.listener;

import com.ssfinder.domain.chat.dto.ChatRoomUpdateMessage;
import com.ssfinder.domain.chat.dto.kafka.KafkaChatMessage;
import com.ssfinder.domain.chat.service.ChatService;
import com.ssfinder.domain.user.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;


/**
 * packageName    : com.ssfinder.domain.chat.kafka.listener<br>
 * fileName       : ChatRoomListUpdateListener.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-08<br>
 * description    : 채팅방 리스트 업데이트 consumer 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-08          nature1216          최초생성<br>
 * <br>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ChatRoomListUpdateListener {
    private final SimpMessagingTemplate template;
    private final ChatService chatService;

    @KafkaListener(topics = "${kafka.topic.chat-message-sent}", groupId = "chat-list-update-broadcast-temp", containerFactory = "chatMessageListenerContainerFactory")
    public void listen(KafkaChatMessage message) {
        log.info("[MESSAGE SENT] chat room list is updated: {}", message);

        User opponent = chatService.getOpponentUser(message.senderId(), message.chatRoomId());
        ChatRoomUpdateMessage chatRoomUpdateMessage = ChatRoomUpdateMessage.builder()
                .chatRoomId(message.chatRoomId())
                .latestMessage(message.content())
                .latestSentAt(LocalDateTime.now())
                .build();
        template.convertAndSend("/sub/chat-room-list/" + opponent.getId(), chatRoomUpdateMessage);
    }
}
