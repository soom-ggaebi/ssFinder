package com.ssfinder.domain.chat.dto.request;

import jakarta.validation.constraints.NotNull;

import java.util.Objects;

/**
 * packageName    : com.ssfinder.domain.chat.dto.request<br>
 * fileName       : ChatRoomNotificationEnabledRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-04-07<br>
 * description    : 채팅방 알림 설정 요청을 위한 DTO입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-07          okeio           최초생성<br>
 * <br>
 */
public record ChatRoomNotificationEnabledRequest(
        @NotNull Boolean enabled
) {
    /**
     * 알림 설정이 활성화되었는지 여부를 반환합니다.
     *
     * <p>
     * enabled 값이 null이 아니고 true일 경우 true를 반환하며, 그 외에는 false를 반환합니다.
     * </p>
     *
     * @return 알림 설정 활성화 여부
     */
    public boolean isEnabled() {
        return Objects.nonNull(enabled) && enabled;
    }
}
