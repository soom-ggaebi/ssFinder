package com.ssfinder.domain.chat.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.chat.entity.ChatMessageStatus;
import com.ssfinder.domain.chat.entity.MessageType;
import lombok.Builder;

import java.time.LocalDateTime;

@Builder
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record ChatMessageInfo(
        String messageId,
        Integer senderId,
        Integer chatRoomId,
        String content,
        MessageType type,
        ChatMessageStatus status,
        LocalDateTime sentAt
) { }
