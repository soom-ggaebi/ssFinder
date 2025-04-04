package com.ssfinder.domain.chat.service;

import com.ssfinder.domain.chat.dto.KafkaChatMessage;
import com.ssfinder.domain.chat.dto.mapper.ChatMessageMapper;
import com.ssfinder.domain.chat.dto.request.MessageSendRequest;
import com.ssfinder.domain.chat.entity.ChatMessage;
import com.ssfinder.domain.chat.entity.ChatMessageStatus;
import com.ssfinder.domain.chat.entity.ChatRoom;
import com.ssfinder.domain.chat.kafka.producer.ChatMessageProducer;
import com.ssfinder.domain.chat.repository.ChatMessageRepository;
import com.ssfinder.domain.chat.repository.ChatRoomParticipantRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

/**
 * packageName    : com.ssfinder.domain.user.service<br>
 * fileName       : ChatService.java<br>
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
@RequiredArgsConstructor
@Transactional
public class ChatService {
    private final UserService userService;
    private final ChatRoomService chatRoomService;
    private final ChatMessageProducer chatMessageProducer;
    private final ChatMessageMapper chatMessageMapper;
    private final ChatMessageRepository chatMessageRepository;
    private final ChatRoomParticipantRepository chatRoomParticipantRepository;
    private final RedisTemplate<String, String> redisTemplate;

    @Value("${kafka.topic.chat-message-sent}")
    private String KAFKA_TOPIC_MESSAGE_SENT;
    @Value("${redis.chat.users.key}")
    private String REDIS_CHAT_USERS_KEY;

    public void send(Integer userId, Integer chatRoomId, MessageSendRequest request) {
        preCheckBeforeSend(userId, chatRoomId);

        User user = userService.findUserById(userId);
        User opponentUser = getOpponentUser(userId, chatRoomId);

        ChatMessage chatMessage = ChatMessage.builder()
                .chatRoomId(chatRoomId)
                .senderId(user.getId())
                .content(request.content())
                .status(checkStatus(opponentUser.getId(), chatRoomId))
                .type(request.type())
                .build();

        ChatMessage message = chatMessageRepository.save(chatMessage);

        KafkaChatMessage kafkaChatMessage = chatMessageMapper.mapToMessageSendResponse(message, user.getNickname());

        chatMessageProducer.publish(KAFKA_TOPIC_MESSAGE_SENT, kafkaChatMessage);
    }

    public User getOpponentUser(Integer userId, Integer chatRoomId) {
        ChatRoom chatRoom = chatRoomService.findById(chatRoomId);
        User user = userService.findUserById(userId);
        return chatRoomParticipantRepository.getChatRoomParticipantByChatRoomAndUserIsNot(chatRoom, user).getUser();
    }

    private void preCheckBeforeSend(Integer userId, Integer chatRoomId) {
        if(!chatRoomService.isInChatRoom(chatRoomId, userId)) {
            throw new CustomException(ErrorCode.CHAT_ROOM_ACCESS_DENIED);
        }
    }

    private ChatMessageStatus checkStatus(Integer userId, Integer chatRoomId) {
        boolean isViewing = Boolean.TRUE.equals(redisTemplate.opsForSet().isMember(REDIS_CHAT_USERS_KEY + chatRoomId, userId.toString()));
        return isViewing ? ChatMessageStatus.READ : ChatMessageStatus.UNREAD;
    }
}
