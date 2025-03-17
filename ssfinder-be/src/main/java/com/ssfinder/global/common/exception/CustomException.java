package com.ssfinder.global.common.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * packageName    : com.ssfinder.global.config.exception<br>
 * fileName       : CustomException.java<br>
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
public class CustomException extends RuntimeException {
    private final ErrorCode errorCode;
}
