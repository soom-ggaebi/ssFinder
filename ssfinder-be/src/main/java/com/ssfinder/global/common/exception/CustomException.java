package com.ssfinder.global.common.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * packageName    : com.ssfinder.global.config.exception<br>
 * fileName       : CustomException.java<br>
 * author         : okeio<br>
 * date           : 2025-03-17<br>
 * description    : 애플리케이션 전반에서 공통적으로 사용하는 사용자 정의 예외 클래스입니다.<br>
 *                  {@link ErrorCode}와 함께 사용되어 예외 발생 시 일관된 응답을 제공합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-17          okeio           최초생성<br>
 * <br>
 */
@AllArgsConstructor
@Getter
public class CustomException extends RuntimeException {
    private final ErrorCode errorCode;
}
