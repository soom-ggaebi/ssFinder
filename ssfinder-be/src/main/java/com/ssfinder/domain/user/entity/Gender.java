package com.ssfinder.domain.user.entity;

/**
 * packageName    : com.ssfinder.domain.user.entity<br>
 * fileName       : Gender.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    : 사용자 성별을 나타내는 열거형입니다.<br>
 *                  MALE, FEMALE 외에 알 수 없는 경우를 위한 UNKNOWN 타입을 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * 2025-03-26          okeio           UNKNOWN 타입 추가<br>
 * <br>
 */
public enum Gender {
    MALE, FEMALE, UNKNOWN;

    /**
     * 문자열 값을 기반으로 Gender enum을 반환합니다.
     * 유효하지 않거나 null/빈 문자열인 경우 UNKNOWN을 반환합니다.
     *
     * @param value 성별을 나타내는 문자열 (예: "male", "FEMALE")
     * @return 매칭되는 {@link Gender} 값 또는 {@link Gender#UNKNOWN}
     */
    public static Gender from(String value) {
        if (value == null || value.isBlank()) return UNKNOWN;

        try {
            return Gender.valueOf(value.toUpperCase());
        } catch (IllegalArgumentException e) {
            return UNKNOWN;
        }
    }
}
