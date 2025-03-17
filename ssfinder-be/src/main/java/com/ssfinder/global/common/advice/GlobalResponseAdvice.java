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
@RestControllerAdvice
public class GlobalResponseAdvice implements ResponseBodyAdvice<Object> {

    @Override
    public boolean supports(MethodParameter returnType, Class<? extends HttpMessageConverter<?>> converterType) {
        return true;
    }

    @Override
    public Object beforeBodyWrite(Object body, MethodParameter returnType, MediaType selectedContentType, Class<? extends HttpMessageConverter<?>> selectedConverterType, ServerHttpRequest request, ServerHttpResponse response) {
        ApiResponse<?> apiResponse;
//        if (body instanceof ApiResponse) {
//            apiResponse = (ApiResponse<?>) body;
//            response.setStatusCode(HttpStatus.valueOf(apiResponse.status().value()));
//        }
//        else {
//            apiResponse = ApiResponse.success(body);
//            // 기본 성공 응답
//            response.setStatusCode(HttpStatus.OK);
//        }
//        return ApiResponse.ok(body);

        if (returnType.getParameterType() == ApiResponse.class) {
            HttpStatus status = ((ApiResponse<?>) body).status();
            response.setStatusCode(status);
        }

        return body;
    }
}
