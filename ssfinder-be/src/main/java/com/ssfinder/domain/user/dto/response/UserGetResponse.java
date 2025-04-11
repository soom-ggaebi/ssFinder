package com.ssfinder.domain.user.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

/**
 * packageName    : com.ssfinder.domain.user.dto.response<br>
 * fileName       : UserGetResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-03-21<br>
 * description    : 사용자 정보 조회 응답 DTO입니다.<br>
 *                  사용자 ID, 닉네임, 지역, 가입 일자를 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-21          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record UserGetResponse(
        Integer id,
        String nickname,
        String myRegion,
        String createdAt
) {
}
