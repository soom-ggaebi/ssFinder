package com.ssfinder.domain.chat.kafka.listener;

import com.ssfinder.domain.chat.dto.kafka.KafkaChatMessage;
import com.ssfinder.domain.chat.entity.ChatRoom;
import com.ssfinder.domain.chat.repository.ChatRoomRepository;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.chat.kafka.listener<br>
 * fileName       : MessageMetaUpdateListener.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-08<br>
 * description    : 채팅방 메타데이터(마지막으로 전송된 메세지 내용, 시간)를 업데이트하는 consumer 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-08          nature1216          최초생성<br>
 * <br>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MessageInfoUpdateListener {
    private final ChatRoomRepository chatRoomRepository;

    @Transactional
    @KafkaListener(topics = "${kafka.topic.chat-message-sent}", groupId = "chat-message-info-update", containerFactory = "chatMessageListenerContainerFactory")
    public void listen(KafkaChatMessage message) {
        log.info("chat room info is updated: {}", message);

        ChatRoom chatRoom = chatRoomRepository.findById(message.chatRoomId())
                .orElseThrow(() -> new CustomException(ErrorCode.CHAT_ROOM_NOT_FOUND));

        chatRoom.setLatestMessage(message.content());
        chatRoom.setLatestSentAt(LocalDateTime.now());
    }
}
