package com.ssfinder.domain.chat.websocket;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
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

    private final RedisTemplate<String, String> redisTemplate;
    @Value("${redis.chat.session.key}")
    private String REDIS_CHAT_SESSION_KEY;
    @Value("${redis.chat.users.key}")
    private String REDIS_CHAT_USERS_KEY;

    @EventListener
    public void handleSessionConnect(SessionConnectedEvent event) {
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

        redisTemplate.opsForValue().set(REDIS_CHAT_SESSION_KEY + sessionId, chatRoomId + ":" + userId);
        redisTemplate.opsForSet().add(REDIS_CHAT_USERS_KEY + chatRoomId, userId.toString());
    }

    @EventListener
    public void handleSessionDisconnect(SessionDisconnectEvent event) {
        String sessionId = event.getSessionId();
        String value = Objects.requireNonNull(redisTemplate.opsForValue().get(REDIS_CHAT_SESSION_KEY + sessionId));

        String[] parts = value.split(":");
        Integer chatRoomId = Integer.parseInt(parts[0]);
        Integer userId = Integer.parseInt(parts[1]);

        redisTemplate.delete(REDIS_CHAT_SESSION_KEY + sessionId);
        redisTemplate.opsForSet().remove(REDIS_CHAT_USERS_KEY + chatRoomId, userId.toString());

        log.info("[WebSocket DISCONNECT] userId={}, chatRoomId={}", userId, chatRoomId);
    }

}
