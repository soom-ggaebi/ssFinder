package com.ssfinder.domain.notification.dto.response;

import lombok.Builder;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.notification.dto.response<br>
 * fileName       : NotificationSliceResponse*.java<br>
 * author         : okeio<br>
 * date           : 2025-04-02<br>
 * description    :  <br>
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