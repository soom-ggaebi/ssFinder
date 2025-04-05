package com.ssfinder.domain.route.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

import java.time.LocalDateTime;
import java.util.List;

/**
 * packageName    : com.ssfinder.domain.route.dto.request<br>
 * fileName       : RouteCreateRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 경로 저장 Request DTO 입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record RouteCreateRequest(
        String eventType,
        LocalDateTime eventTimestamp,
        List<LocationTrace> route
) { }