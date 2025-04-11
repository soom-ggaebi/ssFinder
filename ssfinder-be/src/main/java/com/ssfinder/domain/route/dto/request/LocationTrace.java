package com.ssfinder.domain.route.dto.request;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.route.dto.request<br>
 * fileName       : LocationTrace.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 사용자 위치 추적 정보를 담는 DTO 클래스입니다.<br>
 *                  시간, 위도, 경도를 포함하여 위치 이력 데이터를 구성합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * <br>
 */
@Getter
@AllArgsConstructor
public class LocationTrace {
    LocalDateTime timestamp;
    Double latitude;
    Double longitude;
}
