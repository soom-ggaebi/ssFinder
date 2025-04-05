package com.ssfinder.domain.chat.kafka.listener;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

/**
 * packageName    : com.ssfinder.domain.chat.kafka.listener<br>
 * fileName       : MessageNotificationListener.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-03<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-03          nature1216          최초생성<br>
 * <br>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MessageNotificationListener {

    @KafkaListener(topics = "${kafka.topic.chat-message-sent}", groupId = "chat-alert-push") // TODO: containerFactory 추가
    public void listen() {
    }
}
