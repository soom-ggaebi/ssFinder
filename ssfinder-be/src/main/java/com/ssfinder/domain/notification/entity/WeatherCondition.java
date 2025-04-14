package com.ssfinder.domain.notification.entity;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * packageName    : com.ssfinder.domain.notification.entity<br>
 * fileName       : WeatherCondition.java<br>
 * author         : okeio<br>
 * date           : 2025-04-01<br>
 * description    : 날씨 상태에 따른 알림 메시지를 정의한 열거형입니다.<br>
 *                  비, 눈, 미세먼지 등 상황에 맞는 문구를 제공합니다.<br>
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
