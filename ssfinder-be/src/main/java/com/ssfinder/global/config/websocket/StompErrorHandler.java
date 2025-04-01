package com.ssfinder.global.config.websocket;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.Message;
import org.springframework.messaging.simp.stomp.StompCommand;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.messaging.support.MessageBuilder;
import org.springframework.web.socket.messaging.StompSubProtocolErrorHandler;

/**
 * packageName    : com.ssfinder.global.config.websocket<br>
 * fileName       : StompErrorHandler.java<br>
 * author         : nature1216 <br>
 * date           : 2025-03-28<br>
 * description    : websocket 연결 중에 발생한 error를 처리하는 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          nature1216          최초생성<br>
 * <br>
 */

@RequiredArgsConstructor
@Configuration
public class StompErrorHandler extends StompSubProtocolErrorHandler {
    @Override
    public Message<byte[]> handleClientMessageProcessingError(Message<byte[]> clientMessage, Throwable ex) {
        String msg = "접속 중 오류가 발생했습니다: " + ex.getMessage();

        StompHeaderAccessor accessor = StompHeaderAccessor.create(StompCommand.ERROR);
        accessor.setMessage(msg);
        accessor.setLeaveMutable(true);

        return MessageBuilder.createMessage(msg.getBytes(), accessor.getMessageHeaders());
    }
}
