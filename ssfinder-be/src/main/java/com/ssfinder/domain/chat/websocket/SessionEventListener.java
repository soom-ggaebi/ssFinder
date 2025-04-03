package com.ssfinder.domain.chat.websocket;

import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

@Slf4j
@Component
public class SessionEventListener {
    @EventListener
    public void handleSessionConnect(SessionConnectedEvent event) {
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(event.getMessage());

        Integer userId = Integer.parseInt(accessor.getUser().getName());
        Integer chatRoomId = Integer.parseInt(accessor.getFirstNativeHeader("chat_room_id"));
        log.info("session connected chat room {}: user {}", chatRoomId, userId);

        // TODO: redis에 접속상태 저장
    }

    @EventListener
    public void handleSessionDisconnect(SessionDisconnectEvent event) {
        String sessionId = event.getSessionId();

        // TODO: sessionId로 userId, chatRoomId 조회
        log.info("session disconnected chatroom {} : user {}");
    }

}
