package com.ssfinder.global.common.dto;

import com.ssfinder.global.common.exception.ErrorCode;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

/**
 * packageName    : com.ssfinder.global.config.exception<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-17<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-17          okeio           최초생성<br>
 * <br>
 */
@Getter
public class ExceptionDto {
        @NotNull
        private final String code;

        @NotNull
        private final String message;

        public ExceptionDto(ErrorCode errorCode) {
                this.code = errorCode.getCode();
                this.message = errorCode.getMessage();
        }

        public static ExceptionDto of(ErrorCode errorCode) {
                return new ExceptionDto(errorCode);
        }
}
