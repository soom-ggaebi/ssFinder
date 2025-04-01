package com.ssfinder.domain.chat.dto.response;

import lombok.Builder;

@Builder
public record ChatRoomEntryResponse(
        Integer chatRoomId
) {}
