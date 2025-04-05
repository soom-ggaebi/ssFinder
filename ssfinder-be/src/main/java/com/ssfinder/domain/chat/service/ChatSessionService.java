package com.ssfinder.domain.chat.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.Objects;

/**
 * packageName    : com.ssfinder.domain.user.service<br>
 * fileName       : ChatSessionService.java<br>
 * author         : nature1216<br>
 * date           : 2025-04-05<br>
 * description    : 채팅방 화면 접속상태를 관리하는 서비스 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-05          nature1216           최초생성<br>
 * <br>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ChatSessionService {

    private final RedisTemplate<String, String> redisTemplate;

    @Value("${redis.chat.session.key}")
    private String REDIS_CHAT_SESSION_KEY;
    @Value("${redis.chat.users.key}")
    private String REDIS_CHAT_USERS_KEY;

    public void saveSession(String sessionId, Integer chatRoomId, Integer userId) {
        redisTemplate.opsForValue().set(REDIS_CHAT_SESSION_KEY + sessionId, chatRoomId + ":" + userId);
        redisTemplate.opsForSet().add(REDIS_CHAT_USERS_KEY + chatRoomId, userId.toString());

        log.info("[Session Saved] sessionId={}, userId={}, chatRoomId={}", sessionId, userId, chatRoomId);
    }

    public void deleteSession(String sessionId) {
        String value = Objects.requireNonNull(redisTemplate.opsForValue().get(REDIS_CHAT_SESSION_KEY + sessionId));

        String[] parts = value.split(":");
        Integer chatRoomId = Integer.parseInt(parts[0]);
        Integer userId = Integer.parseInt(parts[1]);

        redisTemplate.delete(REDIS_CHAT_SESSION_KEY + sessionId);
        redisTemplate.opsForSet().remove(REDIS_CHAT_USERS_KEY + chatRoomId, userId.toString());

        log.info("[Session Deleted] userId={}, chatRoomId={}", userId, chatRoomId);
    }

}
