package com.ssfinder.domain.chat.dto;

import com.ssfinder.domain.chat.entity.ChatMessageStatus;
import com.ssfinder.domain.chat.entity.MessageType;
import lombok.*;

import java.io.Serializable;

/**
 * packageName    : com.ssfinder.domain.chat.dto<br>
 * fileName       : ChatMessageKafka.java<br>
 * author         : nature1216 <br>
 * date           : 2025-03-25<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          nature1216          최초생성<br>
 * <br>
 */
@Getter
@ToString
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KafkaChatMessage implements Serializable {
    private String id;
    private Integer senderId;
    private Integer chatRoomId;
    private String content;
    private MessageType type;
    private ChatMessageStatus status;
}
