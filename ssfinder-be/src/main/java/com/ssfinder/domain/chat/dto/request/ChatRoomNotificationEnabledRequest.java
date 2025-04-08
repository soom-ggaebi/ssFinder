package com.ssfinder.domain.chat.dto.request;

import jakarta.validation.constraints.NotNull;

import java.util.Objects;

/**
 * packageName    : com.ssfinder.domain.chat.dto.request<br>
 * fileName       : ChatRoomNotificationEnabledRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-04-07<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-07          okeio           최초생성<br>
 * <br>
 */
public record ChatRoomNotificationEnabledRequest(
        @NotNull Boolean enabled
) {
    public boolean isEnabled() {
        return Objects.nonNull(enabled) && enabled;
    }
}
