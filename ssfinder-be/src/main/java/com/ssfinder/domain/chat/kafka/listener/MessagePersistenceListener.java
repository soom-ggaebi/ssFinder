package com.ssfinder.domain.chat.kafka.listener;

import com.ssfinder.domain.chat.dto.KafkaChatMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.messaging.simp.SimpMessageSendingOperations;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class MessagePersistenceListener {

    private final SimpMessageSendingOperations template;

    @KafkaListener(topics = "chat.message.sent", containerFactory = "consumerFactory")
    public void receiveMessage(KafkaChatMessage message) {
        log.info("message is sent to /sub/chat-room/" + message.getChatRoomId());
        log.info("message: {}", message);

        template.convertAndSend("/sub/chat-room/" + message.getChatRoomId(), message);
    }
}
