package com.ssfinder.domain.auth.controller;

import com.ssfinder.domain.auth.dto.TokenPair;
import com.ssfinder.domain.auth.dto.request.KakaoLoginRequest;
import com.ssfinder.domain.auth.dto.request.RefreshTokenRequest;
import com.ssfinder.domain.auth.dto.response.KakaoLoginResponse;
import com.ssfinder.domain.auth.service.AuthService;
import com.ssfinder.domain.auth.service.TokenService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import com.ssfinder.global.common.response.ApiResponse;
import com.ssfinder.global.util.JwtUtil;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * packageName    : com.ssfinder.domain.auth.controller<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * <br>
 */
@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final TokenService tokenService;
    private final JwtUtil jwtUtil;

    @PostMapping("/login")
    public ApiResponse<KakaoLoginResponse> kakaoLogin(@Valid @RequestBody KakaoLoginRequest kakaoLoginRequest) {
        log.info("kakaoLoginRequest: {}", kakaoLoginRequest);
        KakaoLoginResponse kakaoLoginResponse = authService.kakaoLoginOrRegister(kakaoLoginRequest);
        return ApiResponse.ok(kakaoLoginResponse);
    }

    @PostMapping("/logout")
    public ApiResponse<?> logout(@AuthenticationPrincipal CustomUserDetails userDetails) {
        tokenService.deleteRefreshToken(userDetails.getUserId());
        return ApiResponse.ok(Map.of("message", "성공적으로 로그아웃 되었습니다."));
    }

    @PostMapping("/refresh")
    public ApiResponse<?> refreshAccessToken(@Valid @RequestBody RefreshTokenRequest refreshTokenRequest) {
        String refreshToken = refreshTokenRequest.refreshToken();

        // 리프레시 토큰 검증
        if (!jwtUtil.validateToken(refreshToken)) {
            throw new CustomException(ErrorCode.INVALID_TOKEN);
        }

        int userId = Integer.parseInt(jwtUtil.getUserIdFromToken(refreshToken));

        // Redis 저장된 값과 비교
        String storedRefreshToken = tokenService.getRefreshToken(userId);
        if (!refreshToken.equals(storedRefreshToken)) {
            throw new CustomException(ErrorCode.INVALID_REFRESH_TOKEN);
        }

        String newAccessToken = jwtUtil.generateAccessToken(userId);

        log.info("새로운 액세스 토큰 발급: {}", newAccessToken);
        return ApiResponse.ok(new TokenPair(newAccessToken, refreshToken));
    }
}
