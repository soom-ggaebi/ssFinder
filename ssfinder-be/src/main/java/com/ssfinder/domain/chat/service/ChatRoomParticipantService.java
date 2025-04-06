package com.ssfinder.domain.chat.service;

import com.ssfinder.domain.chat.entity.ChatRoom;
import com.ssfinder.domain.chat.entity.ChatRoomParticipant;
import com.ssfinder.domain.chat.repository.ChatRoomParticipantRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class ChatRoomParticipantService {
    private final UserService userService;
    private final ChatRoomService chatRoomService;
    private final ChatRoomParticipantRepository chatRoomParticipantRepository;

    public ChatRoomParticipant getChatRoomParticipant(Integer chatRoomId, Integer UserId) {
        User user = userService.findUserById(UserId);
        ChatRoom chatRoom = chatRoomService.findById(chatRoomId);

        return chatRoomParticipantRepository
                .findChatRoomParticipantByChatRoomAndUser(chatRoom, user)
                .orElseThrow(() -> new CustomException(ErrorCode.CHAT_ROOM_PARTICIPANT_NOT_FOUND));
    }
}
