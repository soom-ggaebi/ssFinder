package com.ssfinder.global.common.dto;

import com.ssfinder.global.common.exception.ErrorCode;
import jakarta.validation.constraints.NotNull;
import lombok.Getter;

import java.util.Objects;

/**
 * packageName    : com.ssfinder.global.config.exception<br>
 * fileName       : ExceptionDto.java<br>
 * author         : okeio<br>
 * date           : 2025-03-17<br>
 * description    : 전역 예외 처리에서 사용되는 예외 응답 DTO 클래스입니다.<br>
 *                  {@link ErrorCode}의 코드와 메시지를 포함하며, 커스텀 메시지 추가도 지원합니다.<br>
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

        /**
         * 정적 팩토리 메서드: 기본 메시지 기반 예외 DTO 생성
         *
         * @param errorCode {@link ErrorCode}
         * @return {@link ExceptionDto} 인스턴스
         */
        public static ExceptionDto of(ErrorCode errorCode) {
                return new ExceptionDto(errorCode);
        }

        /**
         * 정적 팩토리 메서드: 기본 + 커스텀 메시지 기반 예외 DTO 생성
         *
         * @param errorCode {@link ErrorCode}
         * @param customMessage 추가 메시지
         * @return {@link ExceptionDto} 인스턴스
         */
        public static ExceptionDto of(ErrorCode errorCode, String customMessage) {
                return new ExceptionDto(errorCode, customMessage);
        }
}
