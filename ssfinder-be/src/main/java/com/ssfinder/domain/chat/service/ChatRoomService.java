package com.ssfinder.domain.chat.service;

import com.ssfinder.domain.chat.entity.ChatRoom;
import com.ssfinder.domain.chat.entity.ChatRoomParticipant;
import com.ssfinder.domain.chat.repository.ChatRoomParticipantRepository;
import com.ssfinder.domain.chat.repository.ChatRoomRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.Setter;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.chat.service<br>
 * fileName       : ChatRoomService.java<br>
 * author         : nature1216 <br>
 * date           : 2025-03-28<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          nature1216          최초생성<br>
 * <br>
 */
@Service
@RequiredArgsConstructor
public class ChatRoomService {
    private final UserService userService;
    private final ChatRoomRepository chatRoomRepository;
    private final ChatRoomParticipantRepository chatRoomParticipantRepository;

    public ChatRoom findById(Integer id) {
        return chatRoomRepository.findById(id)
                .orElseThrow(() -> new CustomException(ErrorCode.CHAT_ROOM_NOT_FOUND));
    }

    public boolean isInChatRoom(Integer chatRoomId, Integer UserId) {
        User user = userService.findUserById(UserId);
        ChatRoom chatRoom = findById(chatRoomId);
        List<ChatRoomParticipant> participants = chatRoomParticipantRepository
                        .findChatRoomParticipantByChatRoomAndUser(chatRoom, user);

        return !participants.isEmpty();
    }
}
