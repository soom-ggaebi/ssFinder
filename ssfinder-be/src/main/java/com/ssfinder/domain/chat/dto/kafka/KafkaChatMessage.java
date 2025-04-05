package com.ssfinder.domain.chat.dto.kafka;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.chat.entity.ChatMessageStatus;
import com.ssfinder.domain.chat.entity.MessageType;
import lombok.Builder;

/**
 * packageName    : com.ssfinder.domain.chat.dto,kakfa<br>
 * fileName       : KafkaChatMessage.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-03<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-03          nature1216          최초생성<br>
 * <br>
 */
@Builder
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record KafkaChatMessage(
        String messageId,
        Integer senderId,
        Integer chatRoomId,
        String nickname,
        String content,
        MessageType type,
        ChatMessageStatus status
) { }
