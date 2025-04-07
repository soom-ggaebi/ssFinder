package com.ssfinder.domain.chat.websocket;

import com.ssfinder.domain.chat.service.ChatService;
import com.ssfinder.domain.chat.service.ChatSessionService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.messaging.Message;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.util.Objects;

@Slf4j
@Component
@RequiredArgsConstructor
public class SessionEventListener {

    private final ChatService chatService;
    private final ChatSessionService chatSessionService;

    @EventListener
    public void handleSessionConnect(SessionConnectedEvent event) {
        log.info("Session connecte event: {}", event);
        StompHeaderAccessor accessor = StompHeaderAccessor.wrap(event.getMessage());
        StompHeaderAccessor connectAccessor = StompHeaderAccessor.wrap(
                (Message<?>) accessor.getHeader(
                        SimpMessageHeaderAccessor.CONNECT_MESSAGE_HEADER
                )
        );

        Integer userId = Integer.parseInt(accessor.getUser().getName());
        Integer chatRoomId = Integer.parseInt(Objects.requireNonNull(connectAccessor.getFirstNativeHeader("chat_room_id")));
        String sessionId = accessor.getSessionId();

        log.info("[WebSocket CONNECT] userId={}, chatRoomId={}, sessionId={}", userId, chatRoomId, sessionId);

        // redis에 접속 상태 저장
        chatSessionService.saveSession(sessionId, chatRoomId, userId);

        // 읽지 않은 메세지 읽음처리
        chatService.handleConnect(userId, chatRoomId);
    }

    @EventListener
    public void handleSessionDisconnect(SessionDisconnectEvent event) {
        String sessionId = event.getSessionId();

        chatSessionService.deleteSession(sessionId);
        log.info("[WebSocket DISCONNECT] sessionId={}", sessionId);
    }

}
