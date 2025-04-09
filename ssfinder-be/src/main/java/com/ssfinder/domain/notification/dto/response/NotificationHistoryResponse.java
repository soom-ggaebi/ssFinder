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
 * description    : 알림 내역 조회 결과를 반환하기 위한 응답 DTO입니다.<br>
 *                  알림 제목, 내용, 유형, 발송 시각, 읽음 여부 및 읽은 시각을 포함합니다.<br>
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