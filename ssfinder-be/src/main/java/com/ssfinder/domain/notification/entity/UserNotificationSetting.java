package com.ssfinder.domain.notification.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.*;

/**
 * packageName    : com.ssfinder.domain.notification.entity<br>
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
@Builder
@Entity
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "user_notification_setting")
public class UserNotificationSetting {
    @Id
    private Integer userId;

    @Builder.Default
    @Column(name = "transfer_notification_enabled")
    private boolean transferNotificationEnabled = true;

    @Builder.Default
    @Column(name = "chat_notification_enabled")
    private boolean chatNotificationEnabled = true;

    @Builder.Default
    @Column(name = "item_reminder_enabled")
    private boolean itemReminderEnabled = true;

    @Builder.Default
    @Column(name = "ai_match_notification_enabled")
    private boolean aiMatchNotificationEnabled = true;
}