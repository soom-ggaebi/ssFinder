package com.ssfinder.global.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;

import java.nio.charset.StandardCharsets;
import java.security.Key;
import java.util.Base64;
import java.util.Date;
import java.util.function.Function;

public class JwtUtil {

    @Value("${jwt.secret}")
    private static String secretKey;

    @Value("${jwt.access-token-validity}")
    private static long accessTokenExpiration;

    @Value("${jwt.refresh-token-validity}")
    private static long refreshTokenExpiration;

    @PostConstruct
    protected static void init() {
        secretKey = Base64.getEncoder().encodeToString(secretKey.getBytes());
    }

    // 비밀키 생성
    private static Key getSigningKey() {
        byte[] keyBytes = secretKey.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    // Access Token 생성
    public static String generateAccessToken(int userId) {
        return generateToken(userId, accessTokenExpiration);
    }

    // Refresh Token 생성
    public static String generateRefreshToken(int userId) {
        return generateToken(userId, refreshTokenExpiration);
    }

    // 토큰 생성 공통 메서드
    private static String generateToken(int userId, long expiration) {
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

    // 토큰에서 사용자 ID 추출
    public static String getUserIdFromToken(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    // 토큰에서 클레임 추출
    public static <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    // 토큰에서 모든 클레임 추출
    private static Claims extractAllClaims(String token) {
        return Jwts.parserBuilder()
                .setSigningKey(getSigningKey())
                .build()
                .parseClaimsJws(token)
                .getBody();
    }

    // 토큰 유효성 검사
    public static boolean validateToken(String token) {
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
