package com.ssfinder.global.common.advice;

import com.ssfinder.global.common.response.ApiResponse;
import org.springframework.core.MethodParameter;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.converter.HttpMessageConverter;
import org.springframework.http.server.ServerHttpRequest;
import org.springframework.http.server.ServerHttpResponse;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseBodyAdvice;

/**
 * packageName    : com.ssfinder.global.config<br>
 * fileName       : GlobalResponseAdvice.java<br>
 * author         : okeio<br>
 * date           : 2025-03-17<br>
 * description    : 전역 응답 가공을 위한 Advice 클래스입니다.<br>
 *                  {@link ApiResponse} 타입의 응답 본문이 반환될 경우, 내부 상태 코드를 실제 HTTP 응답에 반영합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-17          okeio           최초생성<br>
 * <br>
 */
@RestControllerAdvice
public class GlobalResponseAdvice implements ResponseBodyAdvice<Object> {

    /**
     * 응답 변환을 적용할지 여부를 결정합니다.
     * 항상 true를 반환하여 모든 컨트롤러 응답에 적용합니다.
     *
     * @param returnType 메서드 반환 타입
     * @param converterType 메시지 컨버터 타입
     * @return 항상 true
     */
    @Override
    public boolean supports(MethodParameter returnType, Class<? extends HttpMessageConverter<?>> converterType) {
        return true;
    }

    /**
     * 실제 응답 본문을 작성하기 전에 가공 작업을 수행합니다.
     * {@link ApiResponse} 타입인 경우, 내부 status 값을 HTTP 응답 코드로 설정합니다.
     *
     * @param body 컨트롤러에서 반환된 응답 본문
     * @param returnType 반환 타입 정보
     * @param selectedContentType 선택된 Content-Type
     * @param selectedConverterType 선택된 메시지 컨버터
     * @param request 서버 요청
     * @param response 서버 응답
     * @return 가공된 응답 본문
     */
    @Override
    public Object beforeBodyWrite(Object body, MethodParameter returnType, MediaType selectedContentType, Class<? extends HttpMessageConverter<?>> selectedConverterType, ServerHttpRequest request, ServerHttpResponse response) {
        if (returnType.getParameterType() == ApiResponse.class) {
            HttpStatus status = ((ApiResponse<?>) body).status();
            response.setStatusCode(status);
        }

        return body;
    }
}
