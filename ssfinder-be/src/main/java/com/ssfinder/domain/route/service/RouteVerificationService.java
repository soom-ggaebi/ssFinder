package com.ssfinder.domain.route.service;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.route.dto.response.RoutesOverlapResponse;
import com.ssfinder.domain.route.dto.response.VerificationStatus;
import com.ssfinder.domain.route.entity.UserLocation;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Metrics;
import org.springframework.data.geo.Point;
import org.springframework.data.mongodb.core.MongoTemplate;
import org.springframework.data.mongodb.core.query.Criteria;
import org.springframework.data.mongodb.core.query.NearQuery;
import org.springframework.data.mongodb.core.query.Query;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Objects;
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
 * 2025-04-04          okeio           검증 로직 수정 및 mongoTemplate 사용<br>
 * <br>
 */
@Slf4j
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class RouteVerificationService {
    private static final double MAX_DISTANCE_METERS = 10;
    private static final double METERS_TO_KILOMETERS = 1000.0;
    private static final double MAX_DISTANCE_KILOMETERS = MAX_DISTANCE_METERS / METERS_TO_KILOMETERS;

    private final MongoTemplate mongoTemplate;

    public RoutesOverlapResponse verifyRouteOverlap(int finderUserId, int loserUserId, FoundItem foundItem) {
        // 1. 습득물 작성일시 및 위치 조회
        LocalDateTime createdAt = foundItem.getCreatedAt();
        org.locationtech.jts.geom.Point foundPoint = foundItem.getCoordinates();
        org.springframework.data.geo.Point geoPoint = convertToGeoPoint(foundPoint);

        // 2. 습득자가 지나간 여부 및 시간 확인(작성일시보다 이전이면서 가장 가까운 시간으로 채택)
        Distance searchDistance = new Distance(MAX_DISTANCE_KILOMETERS, Metrics.KILOMETERS);
        Optional<LocalDateTime> foundTimeOpt = getLatestTimeBetween(finderUserId, geoPoint, searchDistance, createdAt.toLocalDate().atStartOfDay(), createdAt);
        if (foundTimeOpt.isEmpty()) {
            return createResponse(false, VerificationStatus.NO_FINDER_LOCATION);
        }

        // 3. 추정된 습득 시간을 기반으로 분실자가 지나간 여부 및 시간 확인(저장된 모든 일자에 대해 적용)
        LocalDateTime foundTime = foundTimeOpt.get();
        Optional<LocalDateTime> lostTimeOpt = getEarliestTimeBefore(loserUserId, geoPoint, searchDistance, foundTime);
        if (lostTimeOpt.isEmpty()) {
            return createResponse(false, VerificationStatus.NO_LOSER_LOCATION);
        }
        LocalDateTime lostTime = lostTimeOpt.get();

        // 4. 시간 순서 검증
        if (foundTime.isAfter(lostTime)) {
            log.info("[경로 검증] VERIFIED - 분실 시간: {}, 습득 시간: {}", lostTime, foundTime);
            return createResponse(true, VerificationStatus.VERIFIED);
        } else {
            log.info("[경로 검증] TIME_MISMATCH - 분실 시간: {}, 습득 시간: {}", lostTime, foundTime);
            return createResponse(false, VerificationStatus.TIME_MISMATCH);
        }
    }

    private Point convertToGeoPoint(org.locationtech.jts.geom.Point point) {
        return new Point(point.getX(), point.getY());
    }

    private GeoResults<UserLocation> findNearByUserLocation(int userId, Point point, Distance distance, Criteria additionalCriteria) {
        Criteria baseCriteria = Criteria.where("user_id").is(userId);

        Criteria combinedCriteria = Objects.isNull(additionalCriteria) ?
                baseCriteria : baseCriteria.andOperator(additionalCriteria);

        NearQuery nearQuery = NearQuery.near(point)
                .maxDistance(distance)
                .spherical(true)
                .query(Query.query(combinedCriteria));

        return mongoTemplate.geoNear(nearQuery, UserLocation.class);
    }

    private Optional<LocalDateTime> getLatestTimeBetween(int userId, Point point, Distance distance,
                                                         LocalDateTime startTime, LocalDateTime endTime) {
        Criteria timeCriteria = Criteria.where("timestamp").gte(startTime).lt(endTime);

        GeoResults<UserLocation> geoResults = findNearByUserLocation(userId, point, distance, timeCriteria);

        return geoResults.getContent().stream()
                .map(result -> result.getContent().getTimestamp())
                .max(LocalDateTime::compareTo);
    }

    private Optional<LocalDateTime> getEarliestTimeBefore(int userId, Point point, Distance distance, LocalDateTime endTime) {
        Criteria timeCriteria = Criteria.where("timestamp").lt(endTime);

        GeoResults<UserLocation> geoResults = findNearByUserLocation(userId, point, distance, timeCriteria);

        return geoResults.getContent().stream()
                .map(result -> result.getContent().getTimestamp())
                .min(LocalDateTime::compareTo);
    }

    private RoutesOverlapResponse createResponse(boolean overlapExists, VerificationStatus status) {
        return new RoutesOverlapResponse(overlapExists, status);
    }
}
