package com.ssfinder.domain.chat.service;

import com.ssfinder.domain.chat.dto.response.MessageSendResponse;
import com.ssfinder.domain.chat.dto.request.MessageSendRequest;
import com.ssfinder.domain.chat.entity.ChatMessage;
import com.ssfinder.domain.chat.entity.ChatMessageStatus;
import com.ssfinder.domain.chat.repository.ChatMessageRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
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
    private final ChatMessageRepository chatMessageRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public void send(Integer userId, Integer chatRoomId, MessageSendRequest request) {
        User user = userService.findUserById(userId);

        ChatMessage chatMessage = ChatMessage.builder()
                .chatRoomId(chatRoomId)
                .senderId(user.getId())
                .content(request.content())
                .status(ChatMessageStatus.SENT)
                .type(request.type())
                .build();

        ChatMessage message = chatMessageRepository.save(chatMessage);

        MessageSendResponse response = MessageSendResponse.builder()
                .id(message.getId())
                .chatRoomId(chatRoomId)
                .userId(user.getId())
                .nickname(user.getNickname())
                .content(message.getContent())
                .type(request.type())
                .createdAt(message.getCreatedAt())
                .build();

        messagingTemplate.convertAndSend("/sub/chat-room/" + chatRoomId, response);
    }
}
