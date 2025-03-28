package com.ssfinder.domain.chat.entity;


import jakarta.persistence.EntityListeners;
import jakarta.persistence.Id;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;
import org.springframework.data.mongodb.config.EnableMongoAuditing;
import org.springframework.data.mongodb.config.EnableReactiveMongoAuditing;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.chat.entity<br>
 * fileName       : ChatMessage.java<br>
 * author         : nature1216 <br>
 * date           : 2025-03-25<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          nature1216          최초생성<br>
 * <br>
 */
@Document(collection = "chat_message")
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EntityListeners(AuditingEntityListener.class)
public class ChatMessage {
    @Id
    private String id;

    @Field("sender_id")
    private Integer senderId;

    @Field("chat_room_id")
    private Integer chatRoomId;

    private String content;

    @Field("created_at")
    @CreatedDate
    private LocalDateTime createdAt;

    private MessageType type;

    private ChatMessageStatus status;
}
