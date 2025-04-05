package com.ssfinder.domain.chat.kafka.producer;

import com.ssfinder.domain.chat.dto.kafka.KafkaChatReadMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

/**
 * packageName    : com.ssfinder.domain.chat.kafka.producer<br>
 * fileName       : ChatMessageReadProducer.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-05<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-05          nature1216          최초생성<br>
 * <br>
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ChatMessageReadProducer {
    private final KafkaTemplate<String, KafkaChatReadMessage> kafkaTemplate;

    public void publish(String topic, KafkaChatReadMessage message) {
        kafkaTemplate.send(topic, message);
    }
}
