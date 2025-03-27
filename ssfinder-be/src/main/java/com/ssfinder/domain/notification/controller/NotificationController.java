package com.ssfinder.domain.notification.controller;

import com.ssfinder.domain.notification.dto.request.FcmTokenRequest;
import com.ssfinder.domain.notification.dto.request.SettingUpdateRequest;
import com.ssfinder.domain.notification.dto.request.TokenTestRequest;
import com.ssfinder.domain.notification.dto.response.SettingsGetResponse;
import com.ssfinder.domain.notification.service.FcmMessageService;
import com.ssfinder.domain.notification.service.FcmTokenService;
import com.ssfinder.domain.notification.service.UserNotificationSettingService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;


/**
 * packageName    : com.ssfinder.domain.chat.controller<br>
 * fileName       : NotificationController.java<br>
 * author         : okeio<br>
 * date           : 2025-03-24<br>
 * description    : 알림 기능 API controller 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio            최초생성<br>
 * <br>
 */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {
    private final FcmTokenService fcmTokenService;
    private final FcmMessageService fcmMessageService;
    private final UserNotificationSettingService userNotificationSettingService;

    @PostMapping("/token")
    public ApiResponse<?> registerFcmToken(@AuthenticationPrincipal CustomUserDetails userDetails, @RequestBody FcmTokenRequest fcmTokenRequest) {
        fcmTokenService.registerOrUpdateFcmToken(userDetails.getUserId(), fcmTokenRequest);
        return ApiResponse.created(null);
    }

    @DeleteMapping("/token")
    public ApiResponse<?> deleteFcmToken(@AuthenticationPrincipal CustomUserDetails userDetails, @RequestBody FcmTokenRequest fcmTokenRequest) {
        fcmTokenService.deleteFcmToken(userDetails.getUserId(), fcmTokenRequest);
        return ApiResponse.noContent();
    }

    @GetMapping("/settings")
    public ApiResponse<SettingsGetResponse> getNotificationSettings(@AuthenticationPrincipal CustomUserDetails userDetails) {
        SettingsGetResponse settingsGetResponse = userNotificationSettingService.getUserNotificationSettings(userDetails.getUserId());
        return ApiResponse.ok(settingsGetResponse);
    }

    @PatchMapping("/settings")
    public ApiResponse<?> updateNotificationSettings(@AuthenticationPrincipal CustomUserDetails userDetails, @RequestBody SettingUpdateRequest settingUpdateRequest) {
        userNotificationSettingService.updateUserNotificationSettings(userDetails.getUserId(), settingUpdateRequest);
        return ApiResponse.noContent();
    }

    // token 테스트 용도
    @PostMapping("/test")
    public ApiResponse<?> testFcmToken(@AuthenticationPrincipal CustomUserDetails userDetails, @RequestBody TokenTestRequest tokenTestRequest) {
        List<String> tokens = fcmTokenService.getFcmTokens(userDetails.getUserId());

        fcmMessageService.sendNotificationToUser(tokens.get(0), "테스트다", tokenTestRequest.message(), Map.of("type", "TEST"));

        return ApiResponse.noContent();
    }

}
