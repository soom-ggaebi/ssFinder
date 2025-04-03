package com.ssfinder.domain.notification.dto.request;

import com.ssfinder.domain.notification.entity.NotificationType;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.util.Objects;

/**
 * packageName    : com.ssfinder.domain.notification.dto.request<br>
 * fileName       : NotificationHistoryGetRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-04-03<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-03          okeio           최초생성<br>
 * <br>
 */

public record NotificationHistoryGetRequest(
        @NotNull NotificationType type,
        @Min(value = 0) Integer page,
        @Min(value = 1) @Max(value = 100) Integer size,
        Integer lastId
) {
    public NotificationHistoryGetRequest {
        if (Objects.isNull(page)) page = 0;
        if (Objects.isNull(size)) size = 10;
    }
}
