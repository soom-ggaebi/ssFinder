package com.ssfinder.domain.notification.dto.request;

import com.ssfinder.domain.notification.entity.NotificationType;
import lombok.Builder;

import java.util.HashMap;
import java.util.Map;

/**
 * packageName    : com.ssfinder.domain.notification.dto.request<br>
 * fileName       : AiMatchNotificationRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-04-07<br>
 * description    : AI 기반 분실물 매칭 알림 요청 정보를 담는 DTO입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-07          okeio           최초생성<br>
 * <br>
 */
@Builder
public record AiMatchNotificationRequest(
        Integer foundItemId,
        Integer lostItemId
) {
    /**
     * 알림 발송을 위한 데이터를 Map 형태로 변환합니다.
     *
     * <p>
     * AI_MATCH 타입과 함께 foundItemId, lostItemId를 포함한 Map을 반환합니다.
     * </p>
     *
     * @return 알림 데이터 맵
     */
    public Map<String, String> toAiMatchNotificationMap() {
        Map<String, String> data = new HashMap<>();
        data.put("type", NotificationType.AI_MATCH.name());
        data.put("foundItemId", String.valueOf(foundItemId));
        data.put("lostItemId", String.valueOf(lostItemId));
        return data;
    }
}