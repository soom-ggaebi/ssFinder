package com.ssfinder.domain.auth.dto;

import lombok.Getter;

/**
 * packageName    : com.ssfinder.domain.auth.dto<br>
 * fileName       : LoginResultType.java<br>
 * author         : okeio<br>
 * date           : 2025-03-23<br>
 * description    : 카카오 로그인 시 계정 처리 결과 유형을 나타내는 열거형입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-23          okeio           최초생성<br>
 * <br>
 */
@Getter
public enum LoginResultType {
    NEW_ACCOUNT("신규 계정 생성됨"),
    ALREADY_ACTIVE("이미 활성화된 계정"),
    RECOVERED("복구된 계정"),
    EXPIRED("복구 기간 만료");

    private final String description;

    LoginResultType(String description) {
        this.description = description;
    }
}
