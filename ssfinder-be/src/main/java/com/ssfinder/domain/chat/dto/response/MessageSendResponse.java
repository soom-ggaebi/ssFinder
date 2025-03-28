package com.ssfinder.domain.chat.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.PropertyNamingStrategy;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.chat.entity.MessageType;
import lombok.Builder;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.chat.dto<br>
 * fileName       : MessageSendResponse.java<br>
 * author         : nature1216 <br>
 * date           : 2025-03-26<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-26          nature1216          최초생성<br>
 * <br>
 */
@Builder
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record MessageSendResponse (
    String messageId,
    Integer userId,
    Integer chatRoomId,
    String nickname,
    String content,
    LocalDateTime createdAt,
    MessageType type
) {}