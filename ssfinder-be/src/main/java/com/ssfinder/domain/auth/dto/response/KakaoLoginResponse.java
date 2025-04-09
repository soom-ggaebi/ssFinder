package com.ssfinder.domain.auth.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.auth.dto.LoginResultType;

/**
 * packageName    : com.ssfinder.domain.auth.dto.response<br>
 * fileName       : KakaoLoginResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    : 카카오 로그인 처리 결과를 담는 응답 DTO입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * <br>
 */

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record KakaoLoginResponse (
        String accessToken,
        String refreshToken,
        Long expiresIn,
        LoginResultType resultType
){ }
