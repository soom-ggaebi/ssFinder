package com.ssfinder.domain.chat.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Builder;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.chat.dto<br>
 * fileName       : ChatRoomUpdateMessage.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-08<br>
 * description    : 채팅방 업데이트 웹소켓 브로드캐스트 메세지 dto 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-08          nature1216          최초생성<br>
 * <br>
 */
@Builder
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record ChatRoomUpdateMessage(
        Integer chatRoomId,
        String latestMessage,
        LocalDateTime latestSentAt
) { }
