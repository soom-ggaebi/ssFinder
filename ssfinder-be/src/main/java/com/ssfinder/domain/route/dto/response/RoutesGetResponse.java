package com.ssfinder.domain.route.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.route.dto.request.RouteCreateRequest;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.route.dto.response<br>
 * fileName       : RoutesGetResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 이동 경로 조회 response DTO 입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record RoutesGetResponse(
    List<RouteCreateRequest> routes
) {
}
