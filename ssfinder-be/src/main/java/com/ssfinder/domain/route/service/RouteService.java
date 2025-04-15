package com.ssfinder.domain.route.service;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.service.FoundItemService;
import com.ssfinder.domain.route.dto.mapper.UserLocationMapper;
import com.ssfinder.domain.route.dto.request.RouteCreateRequest;
import com.ssfinder.domain.route.dto.request.RoutesOverlapRequest;
import com.ssfinder.domain.route.dto.response.RoutesGetResponse;
import com.ssfinder.domain.route.dto.response.RoutesOverlapResponse;
import com.ssfinder.domain.route.entity.UserLocation;
import com.ssfinder.domain.route.repository.UserLocationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * packageName    : com.ssfinder.domain.route.service<br>
 * fileName       : RouteService.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 회원 경로 데이터를 저장, 조회하고 경로 겹침 여부를 검증하는 서비스 클래스입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class RouteService {
    private final UserLocationRepository userLocationRepository;
    private final UserLocationMapper userLocationMapper;
    private final FoundItemService foundItemService;
    private final RouteVerificationService routeVerificationService;

    /**
     * 사용자의 경로 정보를 저장합니다.
     *
     * <p>
     * 이 메서드는 `RouteCreateRequest` 객체를 받아 사용자 ID와 함께 경로 정보를 데이터베이스에 저장합니다.
     * </p>
     *
     * @param routeCreateRequest 등록할 경로 요청 정보
     * @param userId 사용자 ID
     */
    public void addRoutes(RouteCreateRequest routeCreateRequest, int userId) {
        List<UserLocation> userLocations = userLocationMapper.toUserLocations(routeCreateRequest, userId);
        userLocationRepository.saveAll(userLocations);
    }

    /**
     * 특정 날짜에 해당하는 사용자의 위치 이력을 조회하여 응답 DTO로 변환합니다.
     *
     * <p>
     * 이 메서드는 지정된 날짜에 대한 사용자의 경로를 조회하고, 이를 {@link RoutesGetResponse} 객체로 변환하여 반환합니다.
     * </p>
     *
     * @param date 조회할 날짜
     * @param userId 사용자 ID
     * @return {@link RoutesGetResponse} 객체
     */
    @Transactional(readOnly = true)
    public RoutesGetResponse getRoutes(LocalDate date, int userId) {
        log.info("[경로 조회] date: {}, userId: {}", date, userId);
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);
        List<UserLocation> userLocations = userLocationRepository.findByUserIdAndTimestampBetween(userId, startOfDay, endOfDay);

        return userLocationMapper.toRoutesGetResponse(userLocations);
    }

    /**
     * 습득자와 분실자의 경로가 실제로 겹치는지 확인하고 결과를 반환합니다.
     *
     * <p>
     * 이 메서드는 `RoutesOverlapRequest`를 받아 습득자와 분실자의 경로가 겹치는지 확인하고,
     * 겹침 여부와 함께 결과를 {@link RoutesOverlapResponse} 객체로 반환합니다.
     * </p>
     *
     * @param request 경로 겹침 확인 요청 정보
     * @return {@link RoutesOverlapResponse} 객체
     */
    public RoutesOverlapResponse checkOverlapRoutes(RoutesOverlapRequest request) {
        FoundItem foundItem = foundItemService.findFoundItemById(request.foundItemId());
        return routeVerificationService.verifyRouteOverlap(
                request.myId(),
                request.opponentId(),
                foundItem
        );
    }
}
