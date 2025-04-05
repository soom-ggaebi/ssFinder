package com.ssfinder.domain.chat.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.chat.dto.ChatRoomFoundItem;
import lombok.Builder;

/**
 * packageName    : com.ssfinder.domain.chat.dto.response<br>
 * fileName       : ChatRoomDetailResponse.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-01<br>
 * description    : 채팅방 상세정보 응답 DTO입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-01          nature1216          최초생성<br>
 * <br>
 */
@Builder
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record ChatRoomDetailResponse (
        Integer chatRoomId,
        Integer opponentId,
        String opponentNickname,
        ChatRoomFoundItem foundItem
) { }
