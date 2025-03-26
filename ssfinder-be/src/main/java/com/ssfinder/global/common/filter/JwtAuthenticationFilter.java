package com.ssfinder.global.common.filter;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssfinder.domain.user.service.UserService;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import com.ssfinder.global.common.response.ApiResponse;
import com.ssfinder.global.util.JwtUtil;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Arrays;
import java.util.Objects;

@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final UserService userService;
    private final ObjectMapper objectMapper;

    private static final String[] AllowUrls = new String[]{
            "/api/auth/",
    };

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        String uri = request.getRequestURI();
        // JWT 검증 제외
        if (Arrays.stream(AllowUrls).anyMatch(uri::startsWith) && !request.getRequestURI().equals("/api/auth/logout")) {
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");
        if (Objects.isNull(authHeader) || !authHeader.startsWith("Bearer ")) {
            writeErrorResponse(response, ErrorCode.UNAUTHORIZED);
            return;
        }

        String token = authHeader.substring(7);
        if (JwtUtil.validateToken(token)) {
            processValidAccessToken(token);
        } else {
            writeErrorResponse(response, ErrorCode.INVALID_TOKEN);
            return;
        }

        filterChain.doFilter(request, response);
    }

    private void processValidAccessToken(String accessToken) {
        UserDetails userDetails = userService.loadUserByUsername(JwtUtil.getUserIdFromToken(accessToken));
        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());

        SecurityContextHolder.getContext().setAuthentication(authentication);
    }

    private void writeErrorResponse(HttpServletResponse response, ErrorCode errorCode) throws IOException {
        response.setStatus(errorCode.getHttpStatus().value());
        response.setContentType("application/json;charset=utf-8");

        ApiResponse<?> apiResponse = ApiResponse.fail(new CustomException(ErrorCode.UNAUTHORIZED));
        String jsonResponse = objectMapper.writeValueAsString(apiResponse);
        response.getWriter().write(jsonResponse);
    }
}
