package com.ssfinder.domain.chat.dto.request;

import com.ssfinder.domain.chat.entity.MessageType;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.hibernate.validator.constraints.Length;

/**
 * packageName    : com.ssfinder.domain.chat.dto<br>
 * fileName       : ChattingRequest.java<br>
 * author         : nature1216 <br>
 * date           : 2025-03-26<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-26          nature1216          최초생성<br>
 * <br>
 */
public record MessageSendRequest (
        @NotNull
        MessageType type,

        @NotBlank @Length(max = 65536)
        String content
) {}
