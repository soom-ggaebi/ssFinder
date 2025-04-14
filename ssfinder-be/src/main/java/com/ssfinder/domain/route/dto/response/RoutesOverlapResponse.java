package com.ssfinder.domain.route.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

/**
 * packageName    : com.ssfinder.domain.route.dto.response<br>
 * fileName       : RoutesOverlapResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 경로 겹침 여부 및 검증 결과를 반환하는 응답 DTO입니다.<br>
 *                  실제 겹침 여부와 일치 상태 코드 정보를 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record RoutesOverlapResponse(
        boolean overlapExists,
        VerificationStatus verifiedStatus
) { }