package com.ssfinder.domain.route.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * packageName    : com.ssfinder.domain.route.dto.response<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-31<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-31          okeio           최초생성<br>
 * <br>
 */
@Getter
@AllArgsConstructor
public enum OverlapStatus {
    NO_FINDER_LOCATION("V001", "습득자는 해당 장소를 지나지 않았습니다."),
    NO_LOSER_LOCATION("V002", "분실자는 해당 장소를 지나지 않았습니다."),
    TIME_MISMATCH("V003", "장소는 일치하지만 시간 조건이 충족되지 않았습니다."),
    VERIFIED("V004", "습득자와 분실자의 경로가 시간순으로 일치합니다. 인증되었습니다.");

    private final String code;
    private final String message;
}
