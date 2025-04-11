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
 * description    : 알림 관련 요청을 처리하는 컨트롤러입니다. <br>
 * 사용자 알림 설정, 알림 토큰 관리, 알림 발송 및 알림 내역 조회/삭제를 처리합니다.<br>
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

    /**
     * 사용자의 FCM 토큰을 등록하거나 업데이트합니다.
     *
     * <p>
     * 동일한 토큰이 이미 존재하는 경우, 해당 토큰의 갱신 시간을 업데이트합니다.
     * 존재하지 않는 경우에는 새롭게 등록합니다.
     * </p>
     *
     * @param userDetails 인증된 사용자 정보
     * @param fcmTokenRequest 등록할 FCM 토큰 요청 정보
     * @return HTTP 201 Created 응답
     */
    @PostMapping("/token")
    public ApiResponse<?> registerFcmToken(@AuthenticationPrincipal CustomUserDetails userDetails, @Valid @RequestBody FcmTokenRequest fcmTokenRequest) {
        fcmTokenService.registerOrUpdateFcmToken(userDetails.getUserId(), fcmTokenRequest);
        return ApiResponse.created(null);
    }

    /**
     * 사용자의 FCM 토큰을 삭제합니다.
     *
     * <p>
     * 사용자의 ID와 토큰 문자열을 기준으로 일치하는 FCM 토큰을 찾아 삭제합니다.
     * </p>
     *
     * @param userDetails 인증된 사용자 정보
     * @param fcmTokenRequest 삭제할 FCM 토큰 요청 정보
     * @return HTTP 204 No Content 응답
     */
    @DeleteMapping("/token")
    public ApiResponse<?> deleteFcmToken(@AuthenticationPrincipal CustomUserDetails userDetails, @Valid @RequestBody FcmTokenRequest fcmTokenRequest) {
        fcmTokenService.deleteFcmTokenByUser(userDetails.getUserId(), fcmTokenRequest);
        return ApiResponse.noContent();
    }

    /**
     * 사용자의 알림 설정 정보를 조회합니다.
     *
     * <p>
     * 사용자가 설정한 알림 타입별 알림 수신 여부를 반환합니다.
     * 설정 정보가 존재하지 않으면 기본값(true)으로 응답합니다.
     * </p>
     *
     * @param userDetails 인증된 사용자 정보
     * @return 사용자의 알림 설정 정보를 포함한 {@link ApiResponse}
     */
    @GetMapping("/settings")
    public ApiResponse<SettingsGetResponse> getNotificationSettings(@AuthenticationPrincipal CustomUserDetails userDetails) {
        SettingsGetResponse settingsGetResponse = userNotificationSettingService.getUserNotificationSettings(userDetails.getUserId());
        return ApiResponse.ok(settingsGetResponse);
    }

    /**
     * 사용자의 알림 설정을 수정합니다.
     *
     * <p>
     * 특정 알림 타입의 활성화 여부를 변경하거나, ALL 타입을 통해 모든 알림 타입을 일괄 수정할 수 있습니다.
     * </p>
     *
     * @param userDetails 인증된 사용자 정보
     * @param settingUpdateRequest 알림 설정 수정 요청 정보
     * @return HTTP 204 No Content 응답
     */
    @PatchMapping("/settings")
    public ApiResponse<?> updateNotificationSettings(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                     @Valid @RequestBody SettingUpdateRequest settingUpdateRequest) {
        userNotificationSettingService.updateUserNotificationSettings(userDetails.getUserId(), settingUpdateRequest);
        return ApiResponse.noContent();
    }

    /**
     * 소지품 리마인더 알림을 발송합니다.
     *
     * <p>
     * 전달받은 날씨 조건에 맞는 안내 문구를 포함하여 FCM 알림을 전송하고, 알림 이력에 기록합니다.
     * 현재는 {@code ITEM_REMINDER} 타입에 대해서만 처리합니다.
     * </p>
     *
     * @param userDetails 인증된 사용자 정보
     * @param notificationRequest 알림 발송 요청 정보
     * @return HTTP 204 No Content 응답
     */
    @PostMapping
    public ApiResponse<?> sendItemReminderNotification(@AuthenticationPrincipal CustomUserDetails userDetails,
                                                       @Valid @RequestBody NotificationRequest notificationRequest) {
        if (NotificationType.ITEM_REMINDER.equals(notificationRequest.type())) {
            log.info("[소지품 알림 발송] userId: {}, weather: {}", userDetails.getUserId(), notificationRequest.weather());
            notificationService.sendItemReminderNotification(userDetails.getUserId(), notificationRequest.weather());
        }

        return ApiResponse.noContent();
    }

    /**
     * 사용자의 알림 내역을 페이징 방식으로 조회합니다.
     *
     * <p>
     * 알림 타입, 페이지 번호, 페이지 크기, 마지막 알림 ID를 기준으로 필터링된 알림 이력을 반환합니다.
     * </p>
     *
     * @param request 알림 내역 조회 요청 정보
     * @param userDetails 인증된 사용자 정보
     * @return 알림 내역 리스트를 포함한 {@link NotificationSliceResponse}
     */
    @GetMapping
    public ApiResponse<NotificationSliceResponse> getNotificationHistory(
            @Valid @ModelAttribute NotificationHistoryGetRequest request,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        NotificationSliceResponse notificationHistorySlice = notificationHistoryService.getNotificationHistory
                (userDetails.getUserId(), request.type(), request.page(), request.size(), request.lastId());

        return ApiResponse.ok(notificationHistorySlice);
    }

    /**
     * 특정 알림 내역을 삭제합니다.
     *
     * <p>
     * 알림 ID와 사용자 ID를 기반으로 해당 알림을 삭제 처리합니다.
     * 이미 삭제된 알림일 경우 예외를 발생시킵니다.
     * </p>
     *
     * @param notificationHistoryId 삭제할 알림 내역 ID
     * @param userDetails 인증된 사용자 정보
     * @return HTTP 204 No Content 응답
     */
    @DeleteMapping("/{id}")
    public ApiResponse<?> deleteNotificationHistory(
            @PathVariable("id") Integer notificationHistoryId,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        notificationHistoryService.deleteNotificationHistory(userDetails.getUserId(), notificationHistoryId);

        return ApiResponse.noContent();
    }

    /**
     * 특정 유형의 알림 내역을 모두 삭제합니다.
     *
     * <p>
     * 사용자의 알림 내역 중 요청된 알림 타입에 해당하는 항목들을 일괄 삭제 처리합니다.
     * </p>
     *
     * @param notificationType 삭제할 알림 유형
     * @param userDetails 인증된 사용자 정보
     * @return HTTP 204 No Content 응답
     */
    @DeleteMapping
    public ApiResponse<?> deleteAllNotificationHistory(
            @RequestParam("type") NotificationType notificationType,
            @AuthenticationPrincipal CustomUserDetails userDetails) {
        notificationHistoryService.deleteNotificationHistoryAllByType(userDetails.getUserId(), notificationType);

        return ApiResponse.noContent();
    }
}
