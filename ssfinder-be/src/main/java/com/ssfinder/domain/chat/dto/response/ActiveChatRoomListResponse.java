package com.ssfinder.domain.chat.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.chat.dto.ChatRoomFoundItem;
import lombok.Builder;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.chat.dto.response<br>
 * fileName       : ActiveChatRoomListResponse.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-07<br>
 * description    : 채팅방 리스트 조회 응답 dto입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-07          nature1216          최초생성<br>
 * <br>
 */
@Builder
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record ActiveChatRoomListResponse (
        Integer chatRoomId,
        String opponentNickname,
        String latestMessage,
        LocalDateTime latestSentAt,
        boolean notificationEnabled,
        ChatRoomFoundItem foundItem
) { }
