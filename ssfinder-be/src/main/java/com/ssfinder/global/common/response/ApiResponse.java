package com.ssfinder.global.common.response;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.dto.ExceptionDto;
import jakarta.annotation.Nullable;
import org.springframework.http.HttpStatus;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.global.config.apiresponse<br>
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

public record ApiResponse<T>(
        @JsonIgnore
        HttpStatus status,
        boolean success,
        @Nullable T data,
        @Nullable ExceptionDto error,
        LocalDateTime timestamp
) {

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(HttpStatus.OK, true, data, null, LocalDateTime.now());
    }

    public static <T> ApiResponse<T> created(@Nullable final T data) {
        return new ApiResponse<>(HttpStatus.CREATED, true, data, null, LocalDateTime.now());
    }

    public static <T> ApiResponse<T> fail(CustomException e) {
        return new ApiResponse<>(e.getErrorCode().getHttpStatus(), false, null, ExceptionDto.of(e.getErrorCode()), LocalDateTime.now());
    }
}
