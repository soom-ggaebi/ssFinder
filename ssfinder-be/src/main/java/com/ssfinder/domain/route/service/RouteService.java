package com.ssfinder.domain.route.service;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.service.FoundItemService;
import com.ssfinder.domain.route.dto.mapper.UserLocationMapper;
import com.ssfinder.domain.route.dto.request.RouteCreateRequest;
import com.ssfinder.domain.route.dto.request.RoutesOverlapRequest;
import com.ssfinder.domain.route.dto.response.OverlapStatus;
import com.ssfinder.domain.route.dto.response.RoutesGetResponse;
import com.ssfinder.domain.route.dto.response.RoutesOverlapResponse;
import com.ssfinder.domain.route.entity.UserLocation;
import com.ssfinder.domain.route.repository.UserLocationRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.locationtech.jts.geom.Point;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Metrics;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

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
    private final FoundItemService foundItemService;

    private final int VERIFICATION_TIME = 5;
    private final double MAX_DISTANCE = 10;

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

    // 습득자 채팅방에서 확인 -> (분실물 안봄)
    // 1. 둘이 그 글이 올라오기 전에 습득 장소를 지나감 -> 습득자가 습득 장소 지나가지 않음 / 분실자가 습득 장소 지나가지 않음
    // 2. 실제로 습득한 사람이 그 지점에서 있던 시간 체크
    // 3. 그 전에 분실한 사람이 그 지점 지나갔어야 함 -> 시간 안 맞음 / 시간까지 맞음(최종 인증)

    public RoutesOverlapResponse checkOverlapRoutes(RoutesOverlapRequest routesOverlapRequest) {
        boolean overlapExists = false;
        OverlapStatus overlapStatus = null;
        FoundItem foundItem = foundItemService.findFoundItemById(routesOverlapRequest.foundItemId());
        // TODO 습득물 게시글 생성 시간으로부터 몇 시간?
        LocalDateTime createdAt = foundItem.getCreatedAt();
        List<UserLocation> 이름추천 = userLocationRepository.findByUserIdAndTimestampBetween
                (routesOverlapRequest.foundUserId(), createdAt.minusHours(VERIFICATION_TIME), createdAt);
        List<UserLocation> 이름추천2 = userLocationRepository.findByUserIdAndTimestampBetween
                (routesOverlapRequest.lostUserId(), createdAt.minusHours(VERIFICATION_TIME), createdAt);

        if (이름추천.isEmpty()) {
            overlapStatus = OverlapStatus.NO_FINDER_LOCATION;
        }

        if (이름추천2.isEmpty()) {
            overlapStatus = OverlapStatus.NO_LOSER_LOCATION;
        }


        // 2. 습득자의 습득 지점 시간 체크
        Point point = foundItem.getCoordinates();
        double x = point.getX();
        double y = point.getY();
        org.springframework.data.geo.Point geoPoint = new org.springframework.data.geo.Point(x, y);
        Distance distance = new Distance(MAX_DISTANCE / 1000, Metrics.KILOMETERS);
        GeoResults<UserLocation> geoResults = userLocationRepository.findByUserIdAndLocationNear
                (routesOverlapRequest.foundUserId(), geoPoint, distance);

        Optional<LocalDateTime> earliestTimeOfFoundUser = geoResults.getContent().stream()
                .map(result -> result.getContent().getTimestamp())
                .min(LocalDateTime::compareTo);

        if (earliestTimeOfFoundUser.isEmpty()) {
            overlapStatus = OverlapStatus.NO_FINDER_LOCATION;
            return new RoutesOverlapResponse(overlapExists, overlapStatus);
        }

        // 3. 그 전에 분실한 사람이 습득 지점 지나갔어야 함
        geoResults = userLocationRepository.findByUserIdAndLocationNear
                (routesOverlapRequest.lostUserId(), geoPoint, distance);

        Optional<LocalDateTime> earliestTimeOfLostUser = geoResults.getContent().stream()
                .map(result -> result.getContent().getTimestamp())
                .min(LocalDateTime::compareTo);

        if (earliestTimeOfLostUser.isEmpty()) {
            overlapStatus = OverlapStatus.NO_LOSER_LOCATION;
            return new RoutesOverlapResponse(overlapExists, overlapStatus);
        }

        if (earliestTimeOfFoundUser.get().isAfter(earliestTimeOfLostUser.get())) {
            overlapStatus = OverlapStatus.TIME_MISMATCH;
        } else {
            overlapStatus = OverlapStatus.VERIFIED;
            overlapExists = true;
        }

        return new RoutesOverlapResponse(overlapExists, overlapStatus);
    }
}
