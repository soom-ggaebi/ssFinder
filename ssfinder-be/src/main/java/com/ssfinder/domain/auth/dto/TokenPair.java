package com.ssfinder.domain.auth.dto;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

/**
 * packageName    : com.ssfinder.domain.auth.dto<br>
 * fileName       : TokenPair.java<br>
 * author         : okeio<br>
 * date           : 2025-03-23<br>
 * description    : 액세스 토큰과 리프레시 토큰을 함께 전달하기 위한 DTO입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-23          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(value = PropertyNamingStrategies.SnakeCaseStrategy.class)
public record TokenPair (
        String accessToken,
        String refreshToken
){
}
