package com.ssfinder.domain.notification.service;

import com.ssfinder.domain.notification.dto.request.SettingUpdateRequest;
import com.ssfinder.domain.notification.dto.response.NotificationSetting;
import com.ssfinder.domain.notification.dto.response.SettingsGetResponse;
import com.ssfinder.domain.notification.entity.NotificationType;
import com.ssfinder.domain.notification.entity.UserNotificationSettings;
import com.ssfinder.domain.notification.repository.UserNotificationSettingRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.notification.service<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class UserNotificationSettingService {
    private final UserNotificationSettingRepository userNotificationSettingRepository;

    public SettingsGetResponse getUserNotificationSettings(Integer userId) {
        UserNotificationSettings settings = userNotificationSettingRepository.findByUserId(userId)
                .orElseGet(() -> {
                    // 설정이 없으면 새로 생성
                    UserNotificationSettings newSettings = new UserNotificationSettings();
                    newSettings.setUserId(userId);
                    return newSettings;
                });
        userNotificationSettingRepository.save(settings);

        NotificationSetting transferNotificationSetting = new NotificationSetting(NotificationType.TRANSFER, settings.isTransferNotificationEnabled());
        NotificationSetting chatNotificationSetting = new NotificationSetting(NotificationType.CHAT, settings.isChatNotificationEnabled());
        NotificationSetting aiMatchNotificationSetting = new NotificationSetting(NotificationType.AI_MATCH, settings.isAiMatchNotificationEnabled());
        NotificationSetting itemReminderNotificationSetting = new NotificationSetting(NotificationType.ITEM_REMINDER, settings.isItemReminderEnabled());

        return new SettingsGetResponse(List.of(transferNotificationSetting, chatNotificationSetting, aiMatchNotificationSetting, itemReminderNotificationSetting));
    }

    public void updateUserNotificationSettings(Integer userId, SettingUpdateRequest settingUpdateRequest) {
        UserNotificationSettings settings = userNotificationSettingRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("User notification settings not found"));

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
        }
    }
}
