package com.ssfinder.domain.chat.service;

import com.ssfinder.domain.chat.dto.response.MessageSendResponse;
import com.ssfinder.domain.chat.dto.request.MessageSendRequest;
import com.ssfinder.domain.chat.entity.ChatMessage;
import com.ssfinder.domain.chat.entity.ChatMessageStatus;
import com.ssfinder.domain.chat.repository.ChatMessageRepository;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import com.ssfinder.global.util.JwtUtil;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.Objects;

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
    private final ChatMessageRepository chatMessageRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public MessageSendResponse send(/*SimpMessageHeaderAccessor accessor,*/Integer userId, Integer chatRoomId, MessageSendRequest request) {
//        Integer userId = getUserIdFromHeader(accessor);

        ChatMessage chatMessage = ChatMessage.builder()
                .chatRoomId(chatRoomId)
                .senderId(userId)
                .content(request.content())
                .status(ChatMessageStatus.SENT)
                .type(request.type())
                .build();

        messagingTemplate.convertAndSend("/sub/chat-room/send/" + chatRoomId, chatMessage);

//        ChatMessage message = chatMessageRepository.save(chatMessage);
//
//        MessageSendResponse response = MessageSendResponse.builder()
//                .id(message.getId())
//                .chatRoomId(chatRoomId)
//                .userId(message.getSenderId())
//                .content(request.content())
//                .type(request.type())
//                .build();

        return null;
    }

    private Integer getUserIdFromHeader(SimpMessageHeaderAccessor accessor) {
        String authorizationHeader = accessor.getFirstNativeHeader("Authorization");

        if(Objects.nonNull(authorizationHeader) && authorizationHeader.startsWith("Bearer ")) {
            String token = authorizationHeader.substring(7);

            try {
                return Integer.parseInt(JwtUtil.getUserIdFromToken(token));
            } catch (Exception e) {
                throw new CustomException(ErrorCode.INVALID_TOKEN);
            }
        }

        throw new CustomException(ErrorCode.UNAUTHORIZED);
    }

}
