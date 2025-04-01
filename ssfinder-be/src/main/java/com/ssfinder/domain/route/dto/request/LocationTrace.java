package com.ssfinder.domain.route.dto.request;

import lombok.AllArgsConstructor;
import lombok.Getter;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.route.dto<br>
 * fileName       : LocationTrace.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 하나의 이동 기록 정보를 나타내는 클래스입니다.  <br>
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
