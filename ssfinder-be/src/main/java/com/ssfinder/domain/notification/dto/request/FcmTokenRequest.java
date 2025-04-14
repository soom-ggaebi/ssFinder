package com.ssfinder.domain.notification.dto.request;

import jakarta.validation.constraints.NotBlank;
import org.hibernate.validator.constraints.Length;

/**
 * packageName    : com.ssfinder.domain.notification.dto.request<br>
 * fileName       : FcmTokenRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-03-24<br>
 * description    : FCM 토큰 등록 및 삭제 요청을 위한 DTO입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio           최초생성<br>
 * <br>
 */
public record FcmTokenRequest(
        @NotBlank @Length(min = 1, max = 255) String token
) { }
