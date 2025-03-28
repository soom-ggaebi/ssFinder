package com.ssfinder.domain.chat.service;

import com.ssfinder.domain.chat.dto.mapper.ChatMessageMapper;
import com.ssfinder.domain.chat.dto.response.MessageSendResponse;
import com.ssfinder.domain.chat.dto.request.MessageSendRequest;
import com.ssfinder.domain.chat.entity.ChatMessage;
import com.ssfinder.domain.chat.entity.ChatMessageStatus;
import com.ssfinder.domain.chat.repository.ChatMessageRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
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
    private final ChatRoomService chatRoomService;
    private final ChatMessageMapper chatMessageMapper;
    private final ChatMessageRepository chatMessageRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public void send(Integer userId, Integer chatRoomId, MessageSendRequest request) {
        preCheckBeforeSend(userId, chatRoomId);

        User user = userService.findUserById(userId);

        ChatMessage chatMessage = ChatMessage.builder()
                .chatRoomId(chatRoomId)
                .senderId(user.getId())
                .content(request.content())
                .status(ChatMessageStatus.SENT)
                .type(request.type())
                .build();

        ChatMessage message = chatMessageRepository.save(chatMessage);

        MessageSendResponse response = chatMessageMapper.mapToMessageSendResponse(message, user.getNickname());

        messagingTemplate.convertAndSend("/sub/chat-room/" + chatRoomId, response);
    }

    private void preCheckBeforeSend(Integer userId, Integer chatRoomId) {
        if(!chatRoomService.isInChatRoom(userId, chatRoomId)) {
            throw new CustomException(ErrorCode.CHAT_ROOM_ACCESS_DENIED);
        }
    }
}
