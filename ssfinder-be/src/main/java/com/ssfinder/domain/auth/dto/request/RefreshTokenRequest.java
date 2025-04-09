package com.ssfinder.domain.auth.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.validation.constraints.NotBlank;

/**
 * packageName    : com.ssfinder.domain.auth.dto.request<br>
 * fileName       : RefreshTokenRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    : 액세스 토큰 재발급을 위한 리프레시 토큰 요청 DTO입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(value = PropertyNamingStrategies.SnakeCaseStrategy.class)
public record RefreshTokenRequest(
        @NotBlank String refreshToken
) { }