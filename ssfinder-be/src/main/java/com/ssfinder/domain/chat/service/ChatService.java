package com.ssfinder.domain.chat.service;

import com.ssfinder.domain.chat.dto.IdOnly;
import com.ssfinder.domain.chat.dto.kafka.KafkaChatMessage;
import com.ssfinder.domain.chat.dto.kafka.KafkaChatReadMessage;
import com.ssfinder.domain.chat.dto.mapper.ChatMessageMapper;
import com.ssfinder.domain.chat.dto.request.MessageSendRequest;
import com.ssfinder.domain.chat.dto.response.ChatMessageGetResponse;
import com.ssfinder.domain.chat.entity.*;
import com.ssfinder.domain.chat.kafka.producer.ChatMessageProducer;
import com.ssfinder.domain.chat.kafka.producer.ChatMessageReadProducer;
import com.ssfinder.domain.chat.repository.ChatMessageRepository;
import com.ssfinder.domain.chat.repository.ChatRoomParticipantRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.pagination.CursorScrollResponse;
import com.ssfinder.global.common.service.S3Service;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.Sort;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

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
    private final S3Service s3Service;
    private final ChatMessageProducer chatMessageProducer;
    private final ChatMessageReadProducer chatMessageReadProducer;
    private final ChatMessageMapper chatMessageMapper;
    private final ChatMessageRepository chatMessageRepository;
    private final ChatRoomParticipantRepository chatRoomParticipantRepository;
    private final RedisTemplate<String, String> redisTemplate;
    private final MongoTemplate mongoTemplate;

    @Value("${kafka.topic.chat-message-sent}")
    private String KAFKA_MESSAGE_SENT_TOPIC;
    @Value("${kafka.topic.chat-read}")
    private String KAFKA_CHAT_READ_TOPIC;
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
        log.info("message sent: {}", kafkaChatMessage);
        chatMessageProducer.publish(KAFKA_MESSAGE_SENT_TOPIC, kafkaChatMessage);
    }

    public KafkaChatMessage sendFile(Integer userId, Integer chatRoomId, MultipartFile image) {
        preCheckBeforeSend(userId, chatRoomId);

        User user = userService.findUserById(userId);
        User opponentUser = getOpponentUser(userId, chatRoomId);

        String newImage = s3Service.uploadChatFile(image);

        ChatMessage chatMessage = ChatMessage.builder()
                .chatRoomId(chatRoomId)
                .senderId(user.getId())
                .content(newImage)
                .status(checkStatus(opponentUser.getId(), chatRoomId))
                .type(MessageType.IMAGE)
                .build();

        ChatMessage message = chatMessageRepository.save(chatMessage);

        KafkaChatMessage kafkaChatMessage = chatMessageMapper.mapToMessageSendResponse(message, user.getNickname());
        log.info("message sent: {}", kafkaChatMessage);
        chatMessageProducer.publish(KAFKA_MESSAGE_SENT_TOPIC, kafkaChatMessage);

        return kafkaChatMessage;
    }

    public User getOpponentUser(Integer userId, Integer chatRoomId) {
        ChatRoom chatRoom = chatRoomService.findById(chatRoomId);
        User user = userService.findUserById(userId);
        return chatRoomParticipantRepository.getChatRoomParticipantByChatRoomAndUserIsNot(chatRoom, user).getUser();
    }

    public void handleConnect(Integer userId, Integer chatRoomId) {
        Query query = new Query(Criteria.where("chat_room_id").is(chatRoomId)
                .and("sender_id").ne(userId)
                .and("status").is(ChatMessageStatus.UNREAD));

        query.fields().include("_id");

        List<IdOnly> objectIds = mongoTemplate.find(query, IdOnly.class, "chat_message");
        List<String> messageIds = objectIds.stream()
                .map(idOnly -> idOnly.id().toHexString())
                .toList();

        KafkaChatReadMessage readMessage = KafkaChatReadMessage.builder()
                .chatRoomId(chatRoomId)
                .userId(userId)
                .messageIds(messageIds)
                .build();

        chatMessageReadProducer.publish(KAFKA_CHAT_READ_TOPIC, readMessage);
    }

    public ChatMessageGetResponse getMessages(Integer userId, Integer chatRoomId, int size, @Nullable String lastMessageId) {
        chatRoomService.getChatRoomParticipant(chatRoomId, userId);

        Query query = new Query(
                Criteria.where("chat_room_id").is(chatRoomId)
        );

        if(lastMessageId != null) {
            query.addCriteria(Criteria.where("_id").lt(lastMessageId));
        }

        query.with(Sort.by(Sort.Direction.DESC, "_id"))
                .limit(size + 1);

        List<ChatMessage> messages = mongoTemplate.find(query, ChatMessage.class);

        CursorScrollResponse<ChatMessage> messageCursor = CursorScrollResponse.of(messages, size);

        long count = mongoTemplate.count(new Query(Criteria.where("chat_room_id").is(chatRoomId)), ChatMessage.class);

        return ChatMessageGetResponse.of(messageCursor, count);
    }

    private void preCheckBeforeSend(Integer userId, Integer chatRoomId) {
        chatRoomService.getChatRoomParticipant(chatRoomId, userId);
        ChatRoomParticipant opponentChatRoomParticipant = chatRoomService.getChatRoomParticipant(chatRoomId, getOpponentUser(userId, chatRoomId).getId());

        if(opponentChatRoomParticipant.getStatus() == ChatRoomStatus.INACTIVE) {
            chatRoomService.activate(opponentChatRoomParticipant);
        }
    }

    private ChatMessageStatus checkStatus(Integer userId, Integer chatRoomId) {
        return isViewingChatRoom(userId, chatRoomId) ?
                ChatMessageStatus.READ : ChatMessageStatus.UNREAD;
    }

    public boolean isViewingChatRoom(Integer userId, Integer chatRoomId) {
        return Boolean.TRUE.equals(redisTemplate.opsForSet().isMember(REDIS_CHAT_USERS_KEY + chatRoomId, userId.toString()));
    }
}
