package com.ssfinder.domain.notification.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.notification.entity.NotificationType;
import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * packageName    : com.ssfinder.domain.notification.dto.response<br>
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
@Getter
@AllArgsConstructor
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class NotificationSetting {
    private NotificationType notificationType;
    private boolean enabled;
}
