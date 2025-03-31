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
 * description    : 회원 경로 관련 Controller 클래스입니다. <br>
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

    @PostMapping
    public ApiResponse<Void> addRoute(@Valid @RequestBody RouteCreateRequest routeCreateRequest,
                                   @AuthenticationPrincipal CustomUserDetails userDetails) {
        routeService.addRoutes(routeCreateRequest, userDetails.getUserId());
        return ApiResponse.created(null);
    }

    @GetMapping
    public ApiResponse<RoutesGetResponse> getRoutes(@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
                                                    @AuthenticationPrincipal CustomUserDetails userDetails) {
        RoutesGetResponse routesGetResponse = routeService.getRoutes(date, userDetails.getUserId());
        return ApiResponse.ok(routesGetResponse);
    }

    // TODO
    @PostMapping("/overlap")
    public ApiResponse<RoutesOverlapResponse> overlapRoutes(@Valid @RequestBody RoutesOverlapRequest routesOverlapRequest) {
        RoutesOverlapResponse routesOverlapResponse = routeService.checkOverlapRoutes();
        return null;
    }
}
