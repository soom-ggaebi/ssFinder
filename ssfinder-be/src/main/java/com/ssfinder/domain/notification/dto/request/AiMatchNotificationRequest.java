package com.ssfinder.domain.notification.dto.request;

import com.ssfinder.domain.notification.entity.NotificationType;

import java.util.HashMap;
import java.util.Map;

/**
 * packageName    : com.ssfinder.domain.notification.dto.request<br>
 * fileName       : AiMatchNotificationRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-04-07<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-07          okeio           최초생성<br>
 * <br>
 */
public record AiMatchNotificationRequest(
        Integer foundItemId,
        Integer lostItemId
) {
    public Map<String, String> toAiMatchNotificationMap() {
        Map<String, String> data = new HashMap<>();
        data.put("type", NotificationType.AI_MATCH.name());
        data.put("foundItemId", String.valueOf(foundItemId));
        data.put("lostItemId", String.valueOf(lostItemId));
        return data;
    }
}