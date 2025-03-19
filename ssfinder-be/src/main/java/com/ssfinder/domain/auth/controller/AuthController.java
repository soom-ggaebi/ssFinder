package com.ssfinder.domain.auth.controller;

import com.ssfinder.domain.auth.dto.request.KakaoLoginRequest;
import com.ssfinder.domain.auth.service.AuthService;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
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
@RestController("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserService userService;
    private final AuthService authService;

    @PostMapping("/login")
    public ApiResponse<?> kakaoLogin(@Valid @RequestBody KakaoLoginRequest kakaoLoginRequest) {
        log.info("kakaoLoginRequest: {}", kakaoLoginRequest);


    }
}
