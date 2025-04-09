package com.ssfinder.domain.notification.dto.response;

import lombok.Builder;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.notification.dto.response<br>
 * fileName       : NotificationSliceResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-04-02<br>
 * description    : 알림 내역의 페이징 응답을 위한 DTO입니다.<br>
 *                  알림 목록과 다음 페이지 존재 여부 정보를 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-02          okeio           최초생성<br>
 * <br>
 */
@Builder
public record NotificationSliceResponse(
        List<NotificationHistoryResponse> content,
        boolean hasNext
) { }