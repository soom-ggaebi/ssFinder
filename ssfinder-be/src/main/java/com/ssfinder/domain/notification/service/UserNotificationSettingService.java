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
 * description    : UserNotificationSetting Entity 와 관련된 Service 클래스입니다. <br>
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

    public SettingsGetResponse getUserNotificationSettings(Integer userId) {
        UserNotificationSetting settings = getOrCreateSettings(userId);

        NotificationSetting transferNotificationSetting = new NotificationSetting(NotificationType.TRANSFER, settings.isTransferNotificationEnabled());
        NotificationSetting chatNotificationSetting = new NotificationSetting(NotificationType.CHAT, settings.isChatNotificationEnabled());
        NotificationSetting aiMatchNotificationSetting = new NotificationSetting(NotificationType.AI_MATCH, settings.isAiMatchNotificationEnabled());
        NotificationSetting itemReminderNotificationSetting = new NotificationSetting(NotificationType.ITEM_REMINDER, settings.isItemReminderEnabled());

        return new SettingsGetResponse(List.of(transferNotificationSetting, chatNotificationSetting, aiMatchNotificationSetting, itemReminderNotificationSetting));
    }

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
