package com.ssfinder.domain.route.controller;

import com.ssfinder.domain.route.dto.request.RouteCreateRequest;
import com.ssfinder.domain.route.dto.request.RoutesOverlapRequest;
import com.ssfinder.domain.route.dto.response.RoutesGetResponse;
import com.ssfinder.domain.route.dto.response.RoutesOverlapResponse;
import com.ssfinder.domain.route.service.RouteService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

/**
 * packageName    : com.ssfinder.domain.route.controller<br>
 * fileName       : RouteController.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 사용자 경로 등록, 조회 및 경로 겹침 여부 확인을 처리하는 컨트롤러입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * <br>
 */
@RestController
@RequestMapping("/api/users/routes")
@RequiredArgsConstructor
public class RouteController {

    private final RouteService routeService;

    /**
     * 사용자의 경로를 등록합니다.
     *
     * <p>
     * 이 메서드는 사용자가 새로운 경로를 등록할 때 호출됩니다. 경로 요청 정보를 받아서 서비스 계층에서 경로를 저장합니다.
     * </p>
     *
     * @param routeCreateRequest 등록할 경로 요청 정보
     * @param userDetails 인증된 사용자 정보
     * @return HTTP 201 Created 응답
     */
    @PostMapping
    public ApiResponse<Void> addRoute(@Valid @RequestBody RouteCreateRequest routeCreateRequest,
                                   @AuthenticationPrincipal CustomUserDetails userDetails) {
        routeService.addRoutes(routeCreateRequest, userDetails.getUserId());
        return ApiResponse.created(null);
    }

    /**
     * 특정 날짜에 해당하는 사용자의 경로 정보를 조회합니다.
     *
     * <p>
     * 사용자가 지정한 날짜에 해당하는 경로 정보를 조회합니다. 반환된 경로는 {@link RoutesGetResponse} 형태로 제공됩니다.
     * </p>
     *
     * @param date 조회할 날짜 (yyyy-MM-dd 형식)
     * @param userDetails 인증된 사용자 정보
     * @return 조회된 경로 정보를 포함한 {@link ApiResponse}
     */
    @GetMapping
    public ApiResponse<RoutesGetResponse> getRoutes(@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
                                                    @AuthenticationPrincipal CustomUserDetails userDetails) {
        RoutesGetResponse routesGetResponse = routeService.getRoutes(date, userDetails.getUserId());
        return ApiResponse.ok(routesGetResponse);
    }

    /**
     * 두 사용자의 경로 간의 겹침 여부를 확인합니다.
     *
     * <p>
     * 이 메서드는 두 사용자의 경로가 겹치는지 여부를 확인합니다. 결과는 {@link RoutesOverlapResponse}로 반환됩니다.
     * </p>
     *
     * @param routesOverlapRequest 겹침 여부 확인 요청 정보
     * @return 겹침 결과를 포함한 {@link ApiResponse}
     */
    @PostMapping("/overlap")
    public ApiResponse<RoutesOverlapResponse> overlapRoutes(@Valid @RequestBody RoutesOverlapRequest routesOverlapRequest) {
        RoutesOverlapResponse routesOverlapResponse = routeService.checkOverlapRoutes(routesOverlapRequest);
        return ApiResponse.ok(routesOverlapResponse);
    }
}
