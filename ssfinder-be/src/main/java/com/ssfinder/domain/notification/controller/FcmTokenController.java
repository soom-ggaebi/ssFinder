package com.ssfinder.domain.notification.controller;

import com.ssfinder.domain.notification.dto.request.FcmTokenRequest;
import com.ssfinder.domain.notification.service.FcmTokenService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * packageName    : com.ssfinder.domain.notification.controller<br>
 * fileName       : FcmTokensController.java<br>
 * author         : okeio<br>
 * date           : 2025-03-24<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio           최초생성<br>
 * <br>
 */
@RestController
@RequestMapping("/api/fcm-tokens")
@RequiredArgsConstructor
public class FcmTokenController {

    private final FcmTokenService fcmTokenService;

    @PostMapping
    public ApiResponse<?> registerFcmToken(@AuthenticationPrincipal CustomUserDetails userDetails, @RequestBody FcmTokenRequest fcmTokenRequest) {
        fcmTokenService.registerFcmToken(userDetails.getUserId(), fcmTokenRequest);
        return ApiResponse.created(null);
    }

    @DeleteMapping
    public ApiResponse<?> deleteFcmToken(@AuthenticationPrincipal CustomUserDetails userDetails, @RequestBody FcmTokenRequest fcmTokenRequest) {
        fcmTokenService.deleteFcmToken(userDetails.getUserId(), fcmTokenRequest);
        return ApiResponse.noContent();
    }
}
