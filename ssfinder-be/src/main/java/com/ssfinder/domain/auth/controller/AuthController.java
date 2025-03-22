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

    @PostMapping("/login")
    public ApiResponse<KakaoLoginResponse> kakaoLogin(@Valid @RequestBody KakaoLoginRequest kakaoLoginRequest) {
        log.info("kakaoLoginRequest: {}", kakaoLoginRequest);
        KakaoLoginResponse kakaoLoginResponse = authService.kakaoLoginOrRegister(kakaoLoginRequest);
        return ApiResponse.ok(kakaoLoginResponse);
    }

    @PostMapping("/logout")
    public ApiResponse<?> logout(@AuthenticationPrincipal CustomUserDetails userDetails) {
        authService.logout(userDetails.getUserId());
        return ApiResponse.noContent();
    }

    @PostMapping("/refresh")
    public ApiResponse<?> refreshAccessToken(@Valid @RequestBody RefreshTokenRequest refreshTokenRequest) {
        TokenPair refreshTokenResponse = authService.refreshAccessToken(refreshTokenRequest);
        return ApiResponse.ok(refreshTokenResponse);
    }
}
