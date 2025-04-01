package com.ssfinder.domain.notification.entity;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * packageName    : com.ssfinder.domain.notification.entity<br>
 * fileName       : WeatherCondition.java<br>
 * author         : okeio<br>
 * date           : 2025-04-01<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-01          okeio           최초생성<br>
 * <br>
 */
@Getter
@AllArgsConstructor
public enum WeatherCondition {
    RAIN("비가 와요. 우산 챙기셨나요?"),
    SNOW("눈이 와요. 목도리 챙기셨나요?"),
    DUSTY("마스크와 소지품 챙기세요!"),
    DEFAULT("혹시 잊으신 물건이 있으신가요?");

    private final String notificationContent;
}
