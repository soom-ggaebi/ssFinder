package com.ssfinder.domain.notification.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.notification.entity.NotificationType;
import lombok.Builder;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.notification.dto.response<br>
 * fileName       : NotificationHistoryResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-04-01<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-01          okeio           최초생성<br>
 * <br>
 */
@Builder
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record NotificationHistoryResponse(
    int id,
    String title,
    String body,
    NotificationType type,
    LocalDateTime sendAt,
    boolean isRead,
    LocalDateTime readAt
) { }