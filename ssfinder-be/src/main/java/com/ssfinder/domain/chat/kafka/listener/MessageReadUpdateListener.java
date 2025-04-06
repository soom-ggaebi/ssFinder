package com.ssfinder.domain.chat.kafka.listener;

import com.ssfinder.domain.chat.dto.kafka.KafkaChatReadMessage;
import com.ssfinder.domain.chat.entity.ChatMessage;
import com.ssfinder.domain.chat.entity.ChatMessageStatus;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.data.mongodb.core.query.Update;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * packageName    : com.ssfinder.domain.chat.kafka.listener<br>
 * fileName       : MessageReadUpdateListener.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-05<br>
 * description    : 메세지를 읽었을 때 db에 읽음처리하는 리스너입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-05          nature1216          최초생성<br>
 * <br>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MessageReadUpdateListener {
    private final MongoTemplate mongoTemplate;

    @KafkaListener(topics = "${kafka.topic.chat-read}", groupId = "chat-message-read-db-update", containerFactory = "chatMessageReadListenerContainerFactory")
    public void listen(KafkaChatReadMessage message) {
        Update update = new Update().set("status", ChatMessageStatus.READ);

        Query query = new Query(
                Criteria.where("chat_room_id").is(message.chatRoomId())
                        .and("_id").in(message.messageIds())
        );

        mongoTemplate.updateMulti(query, update, ChatMessage.class);

        log.info("Message read updated: {}", message);
    }
}
