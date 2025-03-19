package com.ssfinder.domain.auth.service;

import com.ssfinder.domain.auth.dto.TokenPair;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import com.ssfinder.global.util.JwtUtility;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.concurrent.TimeUnit;

@Service
@RequiredArgsConstructor
@Slf4j
public class TokenService {

    private final RedisTemplate<String, String> redisTemplate;

    private final JwtUtility jwtUtility;

    public TokenPair generateTokens(int userId) {
        String accessToken = jwtUtility.generateAccessToken(userId);
        String refreshToken = jwtUtility.generateRefreshToken(userId);

        saveRefreshToken(userId, refreshToken);
        return new TokenPair(accessToken, refreshToken);
    }

    private void saveRefreshToken(int userId, String refreshToken) {
        try {
            redisTemplate.opsForValue().set(String.valueOf(userId), refreshToken, 30, TimeUnit.DAYS);
            log.info("Saved refresh token for user: {}", userId);
        } catch (Exception e) {
            log.error("Failed to save refresh token for user: {}", userId, e);
            throw new CustomException(ErrorCode.TOKEN_STORAGE_FAILED);
        }
    }

    public String getRefreshToken(int userId) {
        return redisTemplate.opsForValue().get(String.valueOf(userId));
    }

    public void deleteRefreshToken(int userId) {
        redisTemplate.delete(String.valueOf(userId));
    }
}
