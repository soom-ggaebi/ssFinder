package com.ssfinder.domain.chat.dto.response;

import com.ssfinder.domain.chat.dto.ChatRoomFoundItem;
import lombok.Builder;

@Builder
public record ChatRoomEntryResponse(
        Integer chatRoomId,
        Integer opponentId,
        String opponentNickname,
        ChatRoomFoundItem chatRoomFoundItem
) {}
