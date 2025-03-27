package com.ssfinder.domain.auth.dto;

import lombok.Getter;

/**
 * packageName    : com.ssfinder.domain.auth.dto<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-23<br>
 * description    :  <br>
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
