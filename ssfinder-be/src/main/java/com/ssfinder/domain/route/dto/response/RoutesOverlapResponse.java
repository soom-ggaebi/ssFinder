package com.ssfinder.domain.route.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

/**
 * packageName    : com.ssfinder.domain.route.dto.response<br>
 * fileName       : RoutesOverlapResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 습득자와 분실자 간 이동 경로 크로스 체크에 대한 response DTO 입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record RoutesOverlapResponse(
        boolean overlapExists,
        OverlapStatus verifiedStatus
) { }