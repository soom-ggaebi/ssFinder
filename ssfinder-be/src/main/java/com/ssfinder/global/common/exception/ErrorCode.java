package com.ssfinder.global.common.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;
import org.springframework.http.HttpStatus;

/**
 * packageName    : com.ssfinder.global.config.exception<br>
 * fileName       : ErrorCode.java<br>
 * author         : okeio<br>
 * date           : 2025-03-17<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-17          okeio           최초생성<br>
 * <br>
 */
@AllArgsConstructor
@Getter
public enum ErrorCode {
    INVALID_INPUT_VALUE( "COMMON-001", HttpStatus.BAD_REQUEST, "유효성 검증에 실패했습니다."),
    INTERNAL_SERVER_ERROR("COMMON-002", HttpStatus.INTERNAL_SERVER_ERROR, "서버에서 처리할 수 없습니다.");

    private final String code;
    private final HttpStatus httpStatus;
    private final String message;
}
