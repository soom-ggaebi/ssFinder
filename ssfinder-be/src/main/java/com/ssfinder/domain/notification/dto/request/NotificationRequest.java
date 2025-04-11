package com.ssfinder.domain.notification.dto.request;

import com.ssfinder.domain.notification.entity.NotificationType;
import com.ssfinder.domain.notification.entity.WeatherCondition;
import jakarta.validation.constraints.NotNull;

/**
 * packageName    : com.ssfinder.domain.notification.dto.request<br>
 * fileName       : NotificationRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    : 알림 발송 요청 정보를 담는 DTO입니다.<br>
 *                  알림 유형과 날씨 조건 정보를 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * <br>
 */
public record NotificationRequest(
        @NotNull NotificationType type,
        @NotNull WeatherCondition weather
) { }