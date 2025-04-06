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
import org.springframework.http.HttpMethod;
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

    private final JwtUtil jwtUtil;
    private final UserService userService;
    private final ObjectMapper objectMapper;

    private static final String[] AllowUrls = new String[]{
            "/api/auth/", "/ws/", "/app", "/api/found-items/filter", "/api/category",
            "/api/found-items/viewport/coordinates"
    };

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        String uri = request.getRequestURI();
        String method = request.getMethod();
        // JWT 검증 제외
        if (Arrays.stream(AllowUrls).anyMatch(uri::startsWith) && !request.getRequestURI().equals("/api/auth/logout")) {
            filterChain.doFilter(request, response);
            return;
        }

        if ( (uri.matches("/api/found-items/\\d+") && HttpMethod.GET.matches(method))
                || (uri.startsWith("/api/found-items/viewport") && HttpMethod.GET.matches(method))
                || (uri.matches("/api/found-items/cluster/detail") && HttpMethod.GET.matches(method))
                || (uri.startsWith("/api/found-items/filter-items") && HttpMethod.GET.matches(method)) ) {

            if (!tryProcessToken(request, response)) {
                return;
            }
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");
        if (Objects.isNull(authHeader) || !authHeader.startsWith("Bearer ")) {
            writeErrorResponse(response, ErrorCode.UNAUTHORIZED);
            return;
        }

        String token = authHeader.substring(7);
        if (jwtUtil.validateToken(token)) {
            processValidAccessToken(token);
        } else {
            writeErrorResponse(response, ErrorCode.INVALID_TOKEN);
            return;
        }

        filterChain.doFilter(request, response);
    }

    private boolean tryProcessToken(HttpServletRequest request, HttpServletResponse response) throws IOException {
        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            if (jwtUtil.validateToken(token)) {
                processValidAccessToken(token);
            } else {
                writeErrorResponse(response, ErrorCode.INVALID_TOKEN);
                return false;
            }
        }
        return true;
    }

    private void processValidAccessToken(String accessToken) {
        UserDetails userDetails = userService.loadUserByUsername(jwtUtil.getUserIdFromToken(accessToken));
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