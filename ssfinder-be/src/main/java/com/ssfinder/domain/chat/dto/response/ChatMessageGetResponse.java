package com.ssfinder.domain.chat.dto.response;

import com.ssfinder.domain.chat.dto.ChatMessageInfo;
import com.ssfinder.domain.chat.entity.ChatMessage;
import com.ssfinder.global.common.pagination.CursorScrollResponse;
import lombok.*;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@ToString
@Getter
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ChatMessageGetResponse {
    private static final String LAST_CURSOR = "";

    private List<ChatMessageInfo> messages = new ArrayList<>();
    private long count;
    private String nextCursor;

    public static ChatMessageGetResponse of(CursorScrollResponse<ChatMessage> messageScroll, Integer userId, long count) {
        if(messageScroll.isLastScroll()) {
            return ChatMessageGetResponse.newLastScroll(messageScroll.getCurrentScrollItems(), userId, count);
        }
        return ChatMessageGetResponse.newScrollHasNext(messageScroll.getCurrentScrollItems(), userId, count, messageScroll.getNextCursor().getId());
    }

    private static ChatMessageGetResponse newLastScroll(List<ChatMessage> messageScroll, Integer userId, long count) {
        return newScrollHasNext(messageScroll, userId, count, LAST_CURSOR);
    }

    private static ChatMessageGetResponse newScrollHasNext(List<ChatMessage> messageScroll, Integer userId, long count, String nextCursor) {
        return new ChatMessageGetResponse(getContents(messageScroll, userId), count, nextCursor);
    }

    private static List<ChatMessageInfo> getContents(List<ChatMessage> messageScroll, Integer userId) {
        return messageScroll.stream()
                .map(
                        message ->
                                ChatMessageInfo.builder()
                                        .messageId(message.getId())
                                        .senderId(message.getSenderId())
                                        .isMine(message.getSenderId() == userId)
                                        .chatRoomId(message.getChatRoomId())
                                        .content(message.getContent())
                                        .type(message.getType())
                                        .status(message.getStatus())
                                        .sentAt(message.getCreatedAt())
                                        .build())
                .collect(Collectors.toList());
    }
}
