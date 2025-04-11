package com.ssfinder.domain.notification.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.notification.dto.response<br>
 * fileName       : SettingsGetResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    : 사용자 알림 설정 조회 응답 DTO입니다.<br>
 *                  사용자가 설정한 알림 목록 정보를 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record SettingsGetResponse(
        List<NotificationSetting> settings
) { }