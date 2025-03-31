package com.ssfinder.domain.chat.service;

import com.ssfinder.domain.chat.dto.ChatRoomFoundItem;
import com.ssfinder.domain.chat.dto.response.ChatRoomEntryResponse;
import com.ssfinder.domain.chat.entity.ChatRoom;
import com.ssfinder.domain.chat.entity.ChatRoomParticipant;
import com.ssfinder.domain.chat.entity.ChatRoomStatus;
import com.ssfinder.domain.chat.repository.ChatRoomParticipantRepository;
import com.ssfinder.domain.chat.repository.ChatRoomRepository;
import com.ssfinder.domain.founditem.dto.mapper.FoundItemMapper;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.service.FoundItemService;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Objects;

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
@Transactional
@RequiredArgsConstructor
public class ChatRoomService {
    private final UserService userService;
    private final FoundItemService foundItemService;
    private final FoundItemMapper foundItemMapper;
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

    public ChatRoomEntryResponse getOrCreateChatRoom(Integer userId, Integer foundItemId) {
        User user = userService.findUserById(userId);
        FoundItem foundItem = foundItemService.findFoundItemById(foundItemId);

        if(Objects.nonNull(userId) && Objects.nonNull(foundItem) && userId == foundItem.getUser().getId()) {
            throw new CustomException(ErrorCode.CANNOT_CHAT_WITH_SELF);
        }

        ChatRoomParticipant participant = chatRoomParticipantRepository
                .findByUserAndFoundItem(userId, foundItemId)
                .orElseGet(
                        () -> createChatRoom(user, foundItem)
                );

        ChatRoomFoundItem chatRoomFoundItem = foundItemMapper.mapToChatRoomFoundItem(foundItem);


        return ChatRoomEntryResponse.builder()
                .chatRoomId(participant.getChatRoom().getId())
                .opponentId(foundItem.getUser().getId())
                .opponentNickname(foundItem.getUser().getNickname())
                .chatRoomFoundItem(chatRoomFoundItem)
                .build();
    }

    private ChatRoomParticipant createChatRoom(User user, FoundItem foundItem) {
        ChatRoom chatRoom = ChatRoom.builder()
                .foundItem(foundItem)
                .build();

        chatRoomRepository.save(chatRoom);

        ChatRoomParticipant chatRoomParticipant = ChatRoomParticipant.builder()
                .chatRoom(chatRoom)
                .status(ChatRoomStatus.ACTIVE)
                .user(user)
                .build();

        chatRoomParticipantRepository.save(chatRoomParticipant);

        return chatRoomParticipant;
    }
}
