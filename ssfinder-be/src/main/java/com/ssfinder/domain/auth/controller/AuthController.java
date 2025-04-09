package com.ssfinder.domain.auth.controller;

import com.ssfinder.domain.auth.dto.TokenPair;
import com.ssfinder.domain.auth.dto.request.KakaoLoginRequest;
import com.ssfinder.domain.auth.dto.request.RefreshTokenRequest;
import com.ssfinder.domain.auth.dto.response.KakaoLoginResponse;
import com.ssfinder.domain.auth.service.AuthService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


/**
 * packageName    : com.ssfinder.domain.auth.controller<br>
 * fileName       : AuthController.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    : 인증 관련 요청을 처리하는 컨트롤러입니다. 카카오 로그인, 로그아웃, 토큰 갱신 기능을 제공합니다.<br>
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

    /**
     * 카카오 로그인을 처리하거나 회원가입을 진행합니다.
     *
     * <p>
     * 카카오 액세스 토큰을 기반으로 사용자를 인증하거나 신규 사용자를 등록한 후,
     * 액세스 토큰과 리프레시 토큰이 포함된 응답을 반환합니다.
     * </p>
     *
     * @param kakaoLoginRequest 카카오 로그인 요청 정보
     * @return 액세스 토큰과 리프레시 토큰이 포함된 {@link ApiResponse} 객체
     */
    @PostMapping("/login")
    public ApiResponse<KakaoLoginResponse> kakaoLogin(@Valid @RequestBody KakaoLoginRequest kakaoLoginRequest) {
        log.info("kakaoLoginRequest: {}", kakaoLoginRequest);
        KakaoLoginResponse kakaoLoginResponse = authService.kakaoLoginOrRegister(kakaoLoginRequest);
        return ApiResponse.ok(kakaoLoginResponse);
    }

    /**
     * 인증된 사용자의 로그아웃을 처리합니다.
     *
     * <p>
     * 이 메서드는 현재 로그인한 사용자의 세션 또는 리프레시 토큰을 무효화합니다.
     * </p>
     *
     * @param userDetails 인증된 사용자 정보
     * @return HTTP 204 No Content 응답을 포함한 {@link ApiResponse} 객체
     */
    @PostMapping("/logout")
    public ApiResponse<?> logout(@AuthenticationPrincipal CustomUserDetails userDetails) {
        authService.logout(userDetails.getUserId());
        return ApiResponse.noContent();
    }

    /**
     * 리프레시 토큰을 이용해 새로운 액세스 토큰을 발급받습니다.
     *
     * <p>
     * 유효한 리프레시 토큰을 검증한 후 새로운 액세스 토큰과 리프레시 토큰을 발급하여 반환합니다.
     * </p>
     *
     * @param refreshTokenRequest 리프레시 토큰 요청 정보
     * @return 새로운 토큰 정보가 포함된 {@link ApiResponse} 객체
     */
    @PostMapping("/refresh")
    public ApiResponse<?> refreshAccessToken(@Valid @RequestBody RefreshTokenRequest refreshTokenRequest) {
        TokenPair refreshTokenResponse = authService.refreshAccessToken(refreshTokenRequest);
        return ApiResponse.ok(refreshTokenResponse);
    }
}
