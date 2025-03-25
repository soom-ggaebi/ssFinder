package com.ssfinder.domain.chat.entity;


import jakarta.persistence.Id;
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
public class ChatMessage {
    @Id
    private int id;

    @Field("sender_id")
    private int senderId;

    @Field("receiver_id")
    private int receiverId;

    @Field("chat_room_id")
    private int chatRoomId;

    private String content;

    @Field("created_at")
    private LocalDateTime createdAt;

    private MessageType type;

    private ChatMessageStatus status;
}
