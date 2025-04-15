package com.ssfinder.domain.route.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.route.dto.request<br>
 * fileName       : RoutesOverlapRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 습득자와 분실자의 경로 겹침 여부를 확인하기 위한 요청 DTO입니다.<br>
 *                  사용자 ID, 상대 사용자 ID, 습득물 ID를 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * 2025-04-15          okeio           필드명 변경<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record RoutesOverlapRequest(
        Integer myId,
        Integer opponentId,
        Integer foundItemId
) { }