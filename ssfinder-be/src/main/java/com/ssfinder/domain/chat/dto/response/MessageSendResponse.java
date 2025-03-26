package com.ssfinder.domain.chat.dto.response;

import com.ssfinder.domain.chat.entity.MessageType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;

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
public record MessageSendResponse (
    String id,
    Integer userId,
    Integer chatRoomId,
    String nickname,
    String content,
    String createdAt,
    MessageType type
) {}