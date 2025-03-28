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
    INVALID_INPUT_VALUE( "COMMON-001", HttpStatus.BAD_REQUEST, "입력값이 유효하지 않습니다. 올바른 형식으로 입력해주세요."),
    INTERNAL_SERVER_ERROR("COMMON-002", HttpStatus.INTERNAL_SERVER_ERROR, "서버에서 처리할 수 없습니다."),

    USER_REGISTRATION_FAILED( "AUTH-001", HttpStatus.INTERNAL_SERVER_ERROR, "회원 가입 처리 중 오류가 발생했습니다."),
    UNAUTHORIZED("AUTH-002", HttpStatus.UNAUTHORIZED, "인증이 필요합니다."),
    INVALID_TOKEN("AUTH-003", HttpStatus.UNAUTHORIZED, "유효하지 않은 토큰입니다."),
    TOKEN_STORAGE_FAILED("AUTH-004", HttpStatus.INTERNAL_SERVER_ERROR, "토큰 저장 중 오류가 발생했습니다."),
    INVALID_REFRESH_TOKEN("AUTH-005", HttpStatus.UNAUTHORIZED, "Redis 리프레시 토큰과 다릅니다."),

    ENCRYPT_FAILED("ENCRYPT-001", HttpStatus.INTERNAL_SERVER_ERROR, "암호화에 실패했습니다."),
    DECRYPT_FAILED("ENCRYPT-002", HttpStatus.INTERNAL_SERVER_ERROR, "복호화에 실패했습니다."),

    USER_NOT_FOUND("USER-001", HttpStatus.NOT_FOUND, "존재하지 않는 회원입니다."),
    USER_DELETED("USER-002", HttpStatus.BAD_REQUEST, "탈퇴한 회원입니다."),

    CATEGORY_NOT_FOUND("CATEGORY-001", HttpStatus.NOT_FOUND, "존재하지 않는 카테고리입니다."),

    FOUND_ITEM_NOT_FOUND("FOUND-001", HttpStatus.NOT_FOUND, "존재하지 않는 습득물입니다."),
    FOUND_ITEM_ACCESS_DENIED("FOUND-002", HttpStatus.FORBIDDEN, "본인만 접근 가능한 항목입니다."),

    BOOKMARK_DUPLICATED ("BOOKMARK-001", HttpStatus.CONFLICT, "이미 등록된 북마크입니다."),
    BOOKMARK_NOT_FOUND("BOOKMARK-002", HttpStatus.NOT_FOUND, "존재하지 않는 북마크입니다."),
    BOOKMARK_ACCESS_DENIED("BOOKMARK-003", HttpStatus.FORBIDDEN, "본인만 접근 가능한 항목입니다."),

    LOST_ITEM_NOT_FOUND("LOST-001", HttpStatus.NOT_FOUND, "존재하지 않는 분실물입니다."),
    LOST_ITEM_ACCESS_DENIED("LOST-002", HttpStatus.FORBIDDEN, "본인만 접근 가능한 항목입니다.");

    private final String code;
    private final HttpStatus httpStatus;
    private final String message;
}
