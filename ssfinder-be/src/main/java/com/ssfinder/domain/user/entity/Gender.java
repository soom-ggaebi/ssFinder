package com.ssfinder.domain.user.entity;

/**
 * packageName    : com.ssfinder.domain.user.entity<br>
 * fileName       : Gender.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    : 회원 성별 Enum 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * 2025-03-26          okeio           UNKNOWN 타입 추가<br>
 * <br>
 */
public enum Gender {
    MALE, FEMALE, UNKNOWN;

    public static Gender from(String value) {
        if (value == null || value.isBlank()) return UNKNOWN;

        try {
            return Gender.valueOf(value.toUpperCase());
        } catch (IllegalArgumentException e) {
            return UNKNOWN;
        }
    }
}
