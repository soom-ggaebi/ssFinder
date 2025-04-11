package com.ssfinder.domain.notification.service;

import com.ssfinder.domain.notification.dto.request.SettingUpdateRequest;
import com.ssfinder.domain.notification.dto.response.NotificationSetting;
import com.ssfinder.domain.notification.dto.response.SettingsGetResponse;
import com.ssfinder.domain.notification.entity.NotificationType;
import com.ssfinder.domain.notification.entity.UserNotificationSetting;
import com.ssfinder.domain.notification.repository.UserNotificationSettingRepository;
import com.ssfinder.domain.user.entity.User;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.notification.service<br>
 * fileName       : UserNotificationSettingService.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    : 사용자 알림 설정 정보를 조회, 갱신 및 초기화하는 서비스 클래스입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * 2025-04-03          okeio           알림 ALL 타입 추가<br>
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class UserNotificationSettingService {
    private final UserNotificationSettingRepository userNotificationSettingRepository;
    private final UserService userService;

    /**
     * 사용자 알림 설정을 조회합니다.
     *
     * <p>
     * 이 메서드는 사용자 ID를 기반으로 해당 사용자의 알림 설정을 조회하고,
     * 각 알림 유형에 대해 사용자가 설정한 상태를 반환합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @return 사용자의 알림 설정을 담은 {@link SettingsGetResponse} 객체
     */
    public SettingsGetResponse getUserNotificationSettings(Integer userId) {
        UserNotificationSetting settings = getOrCreateSettings(userId);

        NotificationSetting transferNotificationSetting = new NotificationSetting(NotificationType.TRANSFER, settings.isTransferNotificationEnabled());
        NotificationSetting chatNotificationSetting = new NotificationSetting(NotificationType.CHAT, settings.isChatNotificationEnabled());
        NotificationSetting aiMatchNotificationSetting = new NotificationSetting(NotificationType.AI_MATCH, settings.isAiMatchNotificationEnabled());
        NotificationSetting itemReminderNotificationSetting = new NotificationSetting(NotificationType.ITEM_REMINDER, settings.isItemReminderEnabled());

        return new SettingsGetResponse(List.of(transferNotificationSetting, chatNotificationSetting, aiMatchNotificationSetting, itemReminderNotificationSetting));
    }

    /**
     * 사용자 알림 설정을 업데이트합니다.
     *
     * <p>
     * 이 메서드는 사용자의 알림 설정을 수정합니다. 특정 알림 유형에 대해 활성화/비활성화 상태를 업데이트하며,
     * 모든 알림을 한 번에 수정할 수도 있습니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param settingUpdateRequest 알림 설정 수정 요청 DTO
     */
    public void updateUserNotificationSettings(Integer userId, SettingUpdateRequest settingUpdateRequest) {
        UserNotificationSetting settings = userNotificationSettingRepository.findByUserId(userId)
                .orElseThrow(() -> new CustomException(ErrorCode.USER_NOTIFICATION_SETTINGS_NOT_FOUND));

        switch(settingUpdateRequest.notificationType()) {
            case TRANSFER:
                settings.setTransferNotificationEnabled(settingUpdateRequest.enabled());
                break;
            case CHAT:
                settings.setChatNotificationEnabled(settingUpdateRequest.enabled());
                break;
            case AI_MATCH:
                settings.setAiMatchNotificationEnabled(settingUpdateRequest.enabled());
                break;
            case ITEM_REMINDER:
                settings.setItemReminderEnabled(settingUpdateRequest.enabled());
                break;
            case ALL:
                settings.setTransferNotificationEnabled(settingUpdateRequest.enabled());
                settings.setChatNotificationEnabled(settingUpdateRequest.enabled());
                settings.setAiMatchNotificationEnabled(settingUpdateRequest.enabled());
                settings.setItemReminderEnabled(settingUpdateRequest.enabled());
                break;
        }
    }

    /**
     * 특정 알림 유형에 대해 사용자의 알림 수신 여부를 확인합니다.
     *
     * <p>
     * 이 메서드는 특정 알림 유형에 대해 사용자가 알림을 받을 수 있도록 설정되었는지 확인합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param notificationType 알림 유형
     * @return 사용자가 알림을 받을 수 있도록 설정된 경우 true, 그렇지 않은 경우 false
     */
    public boolean isNotificationEnabledFor(Integer userId, NotificationType notificationType) {
        try {
            UserNotificationSetting settings = getOrCreateSettings(userId);

            return switch (notificationType) {
                case TRANSFER -> settings.isTransferNotificationEnabled();
                case CHAT -> settings.isChatNotificationEnabled();
                case AI_MATCH -> settings.isAiMatchNotificationEnabled();
                case ITEM_REMINDER -> settings.isItemReminderEnabled();

                default -> throw new CustomException(ErrorCode.INVALID_NOTIFICATION_TYPE);
            };
        } catch (CustomException e) {
            if (e.getErrorCode() == ErrorCode.USER_NOT_FOUND) {
                log.warn("알림 설정 확인 중 사용자를 찾을 수 없음: userId={}", userId);
                return true; // 사용자가 없으면 알림 비활성화로 간주
            }
            throw e;
        }
    }

    /**
     * 사용자 알림 설정을 조회하거나 없을 경우 새로 생성합니다.
     *
     * <p>
     * 이 메서드는 사용자의 알림 설정을 조회하고, 없을 경우 새로 생성하여 반환합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @return {@link UserNotificationSetting} 알림 설정 엔티티
     */
    private UserNotificationSetting getOrCreateSettings(Integer userId) {
        // userId가 존재하는지 확인
        User user = userService.findUserById(userId);

        return userNotificationSettingRepository.findByUserId(user.getId())
                .orElseGet(() -> {
                    UserNotificationSetting newSettings = new UserNotificationSetting();
                    newSettings.setUserId(userId);
                    return userNotificationSettingRepository.save(newSettings);
                });
    }
}
