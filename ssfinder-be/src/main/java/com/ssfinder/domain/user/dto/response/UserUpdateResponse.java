package com.ssfinder.domain.user.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

/**
 * packageName    : com.ssfinder.domain.user.dto.response<br>
 * fileName       : UserUpdateResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-03-21<br>
 * description    : 사용자 정보 수정 결과를 반환하는 응답 DTO입니다.<br>
 *                  수정된 사용자 ID, 닉네임, 지역 정보를 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-21          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record UserUpdateResponse(
        Integer id,
        String nickname,
        String myRegion
) {}
