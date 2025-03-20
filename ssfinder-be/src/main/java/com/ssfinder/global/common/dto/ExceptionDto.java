package com.ssfinder.global.common.dto;

import com.ssfinder.global.common.exception.ErrorCode;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.util.Objects;

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

        public ExceptionDto(ErrorCode errorCode, String customMessage) {
                this.code = errorCode.getCode();
                StringBuilder sb = new StringBuilder();
                sb.append(errorCode.getMessage());
                if (Objects.nonNull(customMessage) && !customMessage.isEmpty()) {
                        sb.append(" ").append(customMessage);
                }
                this.message = sb.toString();
        }

        public static ExceptionDto of(ErrorCode errorCode) {
                return new ExceptionDto(errorCode);
        }

        public static ExceptionDto of(ErrorCode errorCode, String customMessage) {
                return new ExceptionDto(errorCode, customMessage);
        }
}
