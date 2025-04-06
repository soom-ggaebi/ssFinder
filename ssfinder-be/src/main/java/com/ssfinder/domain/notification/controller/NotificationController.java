package com.ssfinder.domain.notification.controller;

import com.ssfinder.domain.notification.dto.request.FcmTokenRequest;
import com.ssfinder.domain.notification.dto.request.NotificationHistoryGetRequest;
import com.ssfinder.domain.notification.dto.request.NotificationRequest;
import com.ssfinder.domain.notification.dto.request.SettingUpdateRequest;
import com.ssfinder.domain.notification.dto.response.NotificationSliceResponse;
import com.ssfinder.domain.notification.dto.response.SettingsGetResponse;
import com.ssfinder.domain.notification.entity.NotificationType;
import com.ssfinder.domain.notification.service.FcmTokenService;
import com.ssfinder.domain.notification.service.NotificationHistoryService;
import com.ssfinder.domain.notification.service.NotificationService;
import com.ssfinder.domain.notification.service.UserNotificationSettingService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;


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
@Slf4j
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {
    private final FcmTokenService fcmTokenService;
    private final UserNotificationSettingService userNotificationSettingService;
    private final NotificationService notificationService;
    private final NotificationHistoryService notificationHistoryService;

    @PostMapping("/token")
    public ApiResponse<?> registerFcmToken(@AuthenticationPrincipal CustomUserDetails userDetails, @Valid @RequestBody FcmTokenRequest fcmTokenRequest) {
        fcmTokenService.registerOrUpdateFcmToken(userDetails.getUserId(), fcmTokenRequest);
        return ApiResponse.created(null);
    }

    @DeleteMapping("/token")
    public ApiResponse<?> deleteFcmToken(@AuthenticationPrincipal CustomUserDetails userDetails, @Valid @RequestBody FcmTokenRequest fcmTokenRequest) {
        fcmTokenService.deleteFcmTokenByUser(userDetails.getUserId(), fcmTokenRequest);
        return ApiResponse.noContent();
    }

    @GetMapping("/settings")
    public ApiResponse<SettingsGetResponse> getNotificationSettings(@AuthenticationPrincipal CustomUserDetails userDetails) {
        SettingsGetResponse settingsGetResponse = userNotificationSettingService.getUserNotificationSettings(userDetails.getUserId());
        return ApiResponse.ok(settingsGetResponse);
    }

    @PatchMapping("/settings")
    public ApiResponse<?> updateNotificationSettings(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                     @Valid @RequestBody SettingUpdateRequest settingUpdateRequest) {
        userNotificationSettingService.updateUserNotificationSettings(userDetails.getUserId(), settingUpdateRequest);
        return ApiResponse.noContent();
    }

    @PostMapping
    public ApiResponse<?> sendItemReminderNotification(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                       @Valid @RequestBody NotificationRequest notificationRequest) {
        if (NotificationType.ITEM_REMINDER.equals(notificationRequest.type())) {
            log.info("[소지품 알림 발송] userId: {}, weather: {}", userDetails.getUserId(), notificationRequest.weather());
            notificationService.sendItemReminderNotification(userDetails.getUserId(), notificationRequest.weather());
        }

        return ApiResponse.noContent();
    }

    @GetMapping
    public ApiResponse<NotificationSliceResponse> getNotificationHistory(
            @Valid @ModelAttribute NotificationHistoryGetRequest request,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        NotificationSliceResponse notificationHistorySlice = notificationHistoryService.getNotificationHistory
                (userDetails.getUserId(), request.type(), request.page(), request.size(), request.lastId());

        return ApiResponse.ok(notificationHistorySlice);
    }

    @DeleteMapping("/{id}")
    public ApiResponse<?> deleteNotificationHistory(
            @PathVariable("id") Integer notificationHistoryId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        notificationHistoryService.deleteNotificationHistory(userDetails.getUserId(), notificationHistoryId);

        return ApiResponse.noContent();
    }

    @DeleteMapping
    public ApiResponse<?> deleteAllNotificationHistory(
            @RequestParam("type") NotificationType notificationType,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        notificationHistoryService.deleteNotificationHistoryAllByType(userDetails.getUserId(), notificationType);

        return ApiResponse.noContent();
    }
}
