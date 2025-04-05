package com.ssfinder.domain.route.service;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.route.dto.response.VerificationStatus;
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

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.route.service<br>
 * fileName       : RouteVerificationService.java<br>
 * author         : okeio<br>
 * date           : 2025-03-31<br>
 * description    : 회원 경로 검증 관련 Service 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-31          okeio           최초생성<br>
 * <br>
 */
@Slf4j
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class RouteVerificationService {
    private static final int VERIFICATION_TIME_HOURS = 5;
    private static final double MAX_DISTANCE_METERS = 10;
    private static final double METERS_TO_KILOMETERS = 1000.0;

    private final UserLocationRepository userLocationRepository;

    public RoutesOverlapResponse verifyRouteOverlap(int foundUserId, int lostUserId, FoundItem foundItem) {
        LocalDateTime createdAt = foundItem.getCreatedAt();
        LocalDateTime verificationStartTime = createdAt.minusHours(VERIFICATION_TIME_HOURS);

        // 1. 사용자 위치 데이터 존재 여부 확인
        if (!hasLocationData(foundUserId, verificationStartTime, createdAt)) {
            return createResponse(false, VerificationStatus.NO_FINDER_LOCATION);
        }

        if (!hasLocationData(lostUserId, verificationStartTime, createdAt)) {
            return createResponse(false, VerificationStatus.NO_LOSER_LOCATION);
        }

        // 2. 습득지점 주변 위치 데이터 가져오기
        Point foundPoint = foundItem.getCoordinates();
        org.springframework.data.geo.Point geoPoint = convertToGeoPoint(foundPoint);
        Distance searchDistance = new Distance(MAX_DISTANCE_METERS / METERS_TO_KILOMETERS, Metrics.KILOMETERS);

        // 3. 습득자와 분실자의 해당 지점 방문 시간 확인
        Optional<LocalDateTime> finderEarliestTime = getEarliestTimeNearPoint(foundUserId, geoPoint, searchDistance);
        if (finderEarliestTime.isEmpty()) {
            return createResponse(false, VerificationStatus.NO_FINDER_LOCATION);
        }

        Optional<LocalDateTime> loserEarliestTime = getEarliestTimeNearPoint(lostUserId, geoPoint, searchDistance);
        if (loserEarliestTime.isEmpty()) {
            return createResponse(false, VerificationStatus.NO_LOSER_LOCATION);
        }

        // 4. 시간 순서 검증 (분실자가 먼저 지나갔어야 함)
        if (finderEarliestTime.get().isAfter(loserEarliestTime.get())) {
            return createResponse(true, VerificationStatus.VERIFIED);
        } else {
            return createResponse(false, VerificationStatus.TIME_MISMATCH);
        }
    }

    private boolean hasLocationData(int userId, LocalDateTime start, LocalDateTime end) {
        List<UserLocation> locations = userLocationRepository.findByUserIdAndTimestampBetween(userId, start, end);
        return !locations.isEmpty();
    }

    private org.springframework.data.geo.Point convertToGeoPoint(Point point) {
        return new org.springframework.data.geo.Point(point.getX(), point.getY());
    }

    private Optional<LocalDateTime> getEarliestTimeNearPoint(int userId, org.springframework.data.geo.Point point, Distance distance) {
        GeoResults<UserLocation> geoResults = userLocationRepository.findByUserIdAndLocationNear(userId, point, distance);

        return geoResults.getContent().stream()
                .map(result -> result.getContent().getTimestamp())
                .min(LocalDateTime::compareTo);
    }

    private RoutesOverlapResponse createResponse(boolean overlapExists, VerificationStatus status) {
        return new RoutesOverlapResponse(overlapExists, status);
    }
}
