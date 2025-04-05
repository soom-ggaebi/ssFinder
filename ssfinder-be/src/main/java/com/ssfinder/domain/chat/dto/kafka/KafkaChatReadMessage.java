package com.ssfinder.domain.chat.dto.kafka;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Builder;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.chat.dto,kakfa<br>
 * fileName       : KafkaReadMessage.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-05<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-035         nature1216          최초생성<br>
 * <br>
 */
@Builder
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record KafkaChatReadMessage(
        Integer chatRoomId,
        Integer userId,
        List<String> messageIds
) { }
