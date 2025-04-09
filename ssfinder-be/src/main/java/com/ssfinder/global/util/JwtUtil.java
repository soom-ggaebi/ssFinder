package com.ssfinder.global.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.encrypt.Encryptors;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Base64;
import java.util.Collections;
import java.util.Date;
import java.util.function.Function;

/**
 * packageName    : com.ssfinder.global.util<br>
 * fileName       : EncryptionUtil.java<br>
 * author         : okeio<br>
 * date           : 2025-03-20<br>
 * description    : 문자열 암호화 및 복호화를 처리하는 유틸리티 클래스입니다.<br>
 *                  Spring Security의 {@link Encryptors#text(CharSequence, CharSequence)}를 사용하여 암호화를 수행합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-20        okeio              최초 생성<br>
 * 2025-03-27        nature1216         getAuthentication 메서드 작성<br>
 * <br>
 */
@Component
@RequiredArgsConstructor
public class JwtUtil {

    @Value("${jwt.secret}")
    private String secretKey;

    @Value("${jwt.access-token-validity}")
    private long accessTokenExpiration;

    @Value("${jwt.refresh-token-validity}")
    private long refreshTokenExpiration;

    /**
     * secretKey를 Base64 인코딩하여 초기화합니다.
     * <p>{@link PostConstruct}를 통해 객체 생성 후 호출됩니다.</p>
     */
    @PostConstruct
    protected void init() {
        secretKey = Base64.getEncoder().encodeToString(secretKey.getBytes());
    }

    /**
     * JWT 서명을 위한 HMAC 키를 생성합니다.
     *
     * @return HMAC-SHA 키 객체
     */
    private Key getSigningKey() {
        byte[] keyBytes = secretKey.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    /**
     * Access Token을 생성합니다.
     *
     * @param userId 사용자 ID
     * @return 생성된 Access Token
     */
    public String generateAccessToken(int userId) {
        return generateToken(userId, accessTokenExpiration);
    }

    /**
     * Refresh Token을 생성합니다.
     *
     * @param userId 사용자 ID
     * @return 생성된 Refresh Token
     */
    public String generateRefreshToken(int userId) {
        return generateToken(userId, refreshTokenExpiration);
    }

    /**
     * 토큰 생성 공통 로직
     *
     * @param userId     사용자 ID
     * @param expiration 토큰 유효 기간 (밀리초)
     * @return 생성된 JWT 문자열
     */
    private String generateToken(int userId, long expiration) {
        long now = System.currentTimeMillis();
        Date issuedAt = new Date(now);
        Date expiresAt = new Date(now + expiration);

        return Jwts.builder()
                .setSubject(String.valueOf(userId))
                .setIssuedAt(issuedAt)
                .setExpiration(expiresAt)
                .signWith(getSigningKey(), SignatureAlgorithm.HS256)
                .compact();
    }

    /**
     * JWT에서 사용자 ID(subject)를 추출합니다.
     *
     * @param token JWT 토큰 문자열
     * @return 사용자 ID
     */
    public String getUserIdFromToken(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    /**
     * JWT 기반으로 Spring Security의 Authentication 객체를 생성합니다.
     *
     * @param token 유효한 JWT
     * @return 생성된 Authentication 객체
     */
    public Authentication getAuthentication(String token) {
        String userId = getUserIdFromToken(token);

        return new UsernamePasswordAuthenticationToken(userId, null, Collections.emptyList());
    }

    /**
     * JWT에서 특정 클레임을 추출합니다.
     *
     * @param token          JWT 토큰 문자열
     * @param claimsResolver 클레임 변환 함수
     * @param <T>            반환할 클레임 타입
     * @return 추출된 클레임 값
     */
    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    /**
     * JWT에서 모든 클레임 정보를 추출합니다.
     *
     * @param token JWT 토큰 문자열
     * @return Claims 객체
     */
    private Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    /**
     * 토큰의 서명 및 유효성을 검증합니다.
     *
     * @param token JWT 토큰 문자열
     * @return 유효한 경우 true, 그렇지 않으면 false
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder()
                    .setSigningKey(getSigningKey())
                    .build()
                    .parseClaimsJws(token);
            return true;
        } catch (Exception e) {
            return false;
        }
    }
}