package com.ssfinder.domain.route.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.route.dto.request.LocationTrace;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.route.dto.response<br>
 * fileName       : RoutesGetResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 특정 날짜의 사용자 경로 데이터를 반환하는 응답 DTO입니다.<br>
 *                  경로는 위치 이력 리스트로 구성됩니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record RoutesGetResponse(
        List<LocationTrace> routes
) {
}
