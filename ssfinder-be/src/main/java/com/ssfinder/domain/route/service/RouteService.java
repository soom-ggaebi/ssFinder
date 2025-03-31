package com.ssfinder.domain.route.service;

import com.ssfinder.domain.route.dto.mapper.UserLocationMapper;
import com.ssfinder.domain.route.dto.request.RouteCreateRequest;
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
 * description    : 회원 경로 관련 Service 클래스입니다. <br>
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

    public void addRoutes(RouteCreateRequest routeCreateRequest, int userId) {
        List<UserLocation> userLocations = userLocationMapper.toUserLocations(routeCreateRequest, userId);
        userLocationRepository.saveAll(userLocations);
    }

    @Transactional(readOnly = true)
    public RoutesGetResponse getRoutes(LocalDate date, int userId) {
        log.info("[경로 조회] date: {}, userId: {}", date, userId);
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = startOfDay.plusDays(1);
        List<UserLocation> userLocations = userLocationRepository.findByUserIdAndTimestampBetween(userId, startOfDay, endOfDay);

        // TODO 히트맵 (경로 분석 추가)
        return userLocationMapper.toRoutesGetResponse(userLocations);
    }

    // TODO
    public RoutesOverlapResponse checkOverlapRoutes() {
        return null;
    }
}
