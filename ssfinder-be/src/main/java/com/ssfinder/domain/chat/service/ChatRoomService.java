package com.ssfinder.domain.chat.service;

import com.ssfinder.domain.chat.dto.ChatRoomFoundItem;
import com.ssfinder.domain.chat.dto.ChatRoomListDetail;
import com.ssfinder.domain.chat.dto.response.ActiveChatRoomListResponse;
import com.ssfinder.domain.chat.dto.response.ChatRoomDetailResponse;
import com.ssfinder.domain.chat.dto.response.ChatRoomEntryResponse;
import com.ssfinder.domain.chat.entity.ChatRoom;
import com.ssfinder.domain.chat.entity.ChatRoomParticipant;
import com.ssfinder.domain.chat.entity.ChatRoomStatus;
import com.ssfinder.domain.chat.repository.ChatRoomParticipantRepository;
import com.ssfinder.domain.chat.repository.ChatRoomRepository;
import com.ssfinder.domain.founditem.dto.mapper.FoundItemMapper;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.service.FoundItemService;
import com.ssfinder.domain.itemcategory.dto.ItemCategoryInfo;
import com.ssfinder.domain.itemcategory.service.ItemCategoryService;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
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
 * 2025-04-07          okeio               채팅방 별 알림 설정 메서드 추가<br>
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class ChatRoomService {
    private final UserService userService;
    private final FoundItemService foundItemService;
    private final ItemCategoryService itemCategoryService;
    private final FoundItemMapper foundItemMapper;
    private final ChatRoomRepository chatRoomRepository;
    private final ChatRoomParticipantRepository chatRoomParticipantRepository;

    @Transactional(readOnly = true)
    public ChatRoom findById(Integer id) {
        return chatRoomRepository.findById(id)
                .orElseThrow(() -> new CustomException(ErrorCode.CHAT_ROOM_NOT_FOUND));
    }

    @Transactional(readOnly = true)
    public ChatRoomParticipant getChatRoomParticipant(Integer chatRoomId, Integer UserId) {
        User user = userService.findUserById(UserId);
        ChatRoom chatRoom = findById(chatRoomId);

        return chatRoomParticipantRepository
                .findChatRoomParticipantByChatRoomAndUser(chatRoom, user)
                .orElseThrow(() -> new CustomException(ErrorCode.CHAT_ROOM_PARTICIPANT_NOT_FOUND));
    }

    public ChatRoomEntryResponse getOrCreateChatRoom(Integer userId, Integer foundItemId) {
        User user = userService.findUserById(userId);
        FoundItem foundItem = foundItemService.findFoundItemById(foundItemId);

        if(Objects.isNull(foundItem.getUser())) {
            throw new CustomException(ErrorCode.NO_FINDER_FOR_ITEM);
        }

        if(Objects.nonNull(userId) && userId == foundItem.getUser().getId()) {
            throw new CustomException(ErrorCode.CANNOT_CHAT_WITH_SELF);
        }

        ChatRoom chatRoom = chatRoomRepository
                .findByUserAndFoundItem(userId, foundItemId)
                .orElseGet(
                        () -> createChatRoom(user, foundItem)
                );

        ChatRoomParticipant participant = getChatRoomParticipant(chatRoom.getId(), userId);

        if(participant.getStatus() == ChatRoomStatus.INACTIVE) {
            activate(participant);
        }

        return ChatRoomEntryResponse.builder()
                .chatRoomId(chatRoom.getId())
                .build();
    }

    @Transactional(readOnly = true)
    public ChatRoomDetailResponse getChatRoomDetail(Integer userId, Integer chatRoomId) {
        ChatRoom chatRoom = findById(chatRoomId);
        FoundItem foundItem = chatRoom.getFoundItem();

        ChatRoomParticipant chatRoomParticipant = getChatRoomParticipant(chatRoomId, userId);

        User user = userService.findUserById(userId);

        ItemCategoryInfo itemCategoryInfo = itemCategoryService
                .findWithParentById(foundItem.getItemCategory().getId());

        User opponentUser = chatRoomParticipantRepository.getChatRoomParticipantByChatRoomAndUserIsNot(chatRoom, user).getUser();

        ChatRoomFoundItem chatRoomFoundItem = foundItemMapper
                .mapToChatRoomFoundItem(foundItem, itemCategoryInfo);

        return ChatRoomDetailResponse.builder()
                .chatRoomId(chatRoomId)
                .opponentId(opponentUser.getId())
                .opponentNickname(opponentUser.getNickname())
                .foundItem(chatRoomFoundItem)
                .build();
    }

    @Transactional(readOnly = true)
    public List<ActiveChatRoomListResponse> getActiveChatRoomList(Integer userId) {
        List<ChatRoomListDetail> chatRooms = chatRoomRepository.findByUserAndStatusIsActive(userId);
        User user = userService.findUserById(userId);

        List<ActiveChatRoomListResponse> response = new ArrayList<>();

        for(ChatRoomListDetail item : chatRooms) {
            ChatRoom chatRoom = item.chatRoom();
            ChatRoomParticipant participant = item.chatRoomParticipant();

            FoundItem foundItem = chatRoom.getFoundItem();

            ItemCategoryInfo itemCategoryInfo = itemCategoryService
                    .findWithParentById(foundItem.getItemCategory().getId());

            ChatRoomFoundItem chatRoomFoundItem = foundItemMapper
                    .mapToChatRoomFoundItem(foundItem, itemCategoryInfo);

            User opponent = chatRoomParticipantRepository
                    .getChatRoomParticipantByChatRoomAndUserIsNot(chatRoom, user)
                    .getUser();

            response.add(
                    ActiveChatRoomListResponse.builder()
                            .foundItem(chatRoomFoundItem)
                            .chatRoomId(chatRoom.getId())
                            .hasUnread(hasUnRead(participant, chatRoom))
                            .notificationEnabled(participant.getNotificationEnabled())
                            .opponentNickname(opponent.getNickname())
                            .latestMessage(chatRoom.getLatestMessage())
                            .latestSentAt(chatRoom.getLatestSentAt())
                            .build()
            );
        }

        return response;
    }

    public void leave(Integer userId, Integer chatRoomId) {
        ChatRoomParticipant chatRoomParticipant = getChatRoomParticipant(chatRoomId, userId);

        deactivate(chatRoomParticipant);
    }

    public void activate(ChatRoomParticipant participant) {
        participant.setLeftAt(null);
        participant.setRejoinedAt(LocalDateTime.now());
        participant.setStatus(ChatRoomStatus.ACTIVE);
    }

    public void updateNotificationEnabled(Integer userId, Integer chatRoomId, boolean enabled) {
        ChatRoomParticipant chatRoomParticipant = getChatRoomParticipant(chatRoomId, userId);
        chatRoomParticipant.setNotificationEnabled(enabled);
    }

    private boolean hasUnRead(ChatRoomParticipant participant, ChatRoom chatRoom) {
        return chatRoom.getLatestSentAt().isAfter(participant.getLastReadAt());
    }

    private void deactivate(ChatRoomParticipant participant) {
        participant.setLeftAt(LocalDateTime.now());
        participant.setStatus(ChatRoomStatus.INACTIVE);
    }

    private ChatRoom createChatRoom(User user, FoundItem foundItem) {
        ChatRoom chatRoom = ChatRoom.builder()
                .foundItem(foundItem)
                .latestSentAt(LocalDateTime.now())
                .build();

        chatRoomRepository.save(chatRoom);

        chatRoomParticipantRepository.save(ChatRoomParticipant.builder()
                .chatRoom(chatRoom)
                .status(ChatRoomStatus.ACTIVE)
                .user(user)
                .lastReadAt(LocalDateTime.now())
                .build());



        chatRoomParticipantRepository.save(ChatRoomParticipant.builder()
                .chatRoom(chatRoom)
                .status(ChatRoomStatus.ACTIVE)
                .user(foundItem.getUser())
                .lastReadAt(LocalDateTime.now())
                .build()
        );

        return chatRoom;
    }
}
