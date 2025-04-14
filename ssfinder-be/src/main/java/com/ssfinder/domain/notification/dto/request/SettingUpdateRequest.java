package com.ssfinder.domain.notification.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.notification.entity.NotificationType;
import jakarta.validation.constraints.NotNull;

/**
 * packageName    : com.ssfinder.domain.notification.dto.request<br>
 * fileName       : SettingUpdateRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    : 사용자 알림 설정을 수정하기 위한 요청 DTO입니다.<br>
 *                  알림 유형과 알림 활성화 여부를 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record SettingUpdateRequest(
        @NotNull NotificationType notificationType,
        @NotNull Boolean enabled
) {}