package com.ssfinder.domain.route.service;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.route.dto.response.RoutesOverlapResponse;
import com.ssfinder.domain.route.dto.response.VerificationStatus;
import com.ssfinder.domain.route.entity.UserLocation;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
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

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Objects;
import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.route.service<br>
 * fileName       : RouteVerificationService.java<br>
 * author         : okeio<br>
 * date           : 2025-03-31<br>
 * description    : 습득자와 분실자의 경로 및 시간 겹침 여부를 검증하는 서비스 클래스입니다.<br>
 *                  GeoSpatial 쿼리를 통해 근접 위치 데이터를 기반으로 교차 여부를 판단합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-31          okeio           최초생성<br>
 * 2025-04-04          okeio           검증 로직 수정 및 mongoTemplate 사용<br>
 * 2025-04-13          okeio           습득물 게시글의 생성일시 대신 습득일자 기준으로 검증 로직 변경<br>
 * <br>
 */
@Slf4j
@Service
@Transactional(readOnly = true)
@RequiredArgsConstructor
public class RouteVerificationService {
    private static final double MAX_DISTANCE_METERS = 500;
    private static final double METERS_TO_KILOMETERS = 1000.0;
    private static final double MAX_DISTANCE_KILOMETERS = MAX_DISTANCE_METERS / METERS_TO_KILOMETERS;

    private final MongoTemplate mongoTemplate;

    /**
     * 습득자와 분실자의 위치 및 시간 데이터를 기반으로 경로 겹침 여부를 검증합니다.
     *
     * <p>
     * 이 메서드는 습득자의 위치와 분실자의 위치를 비교하여 경로가 겹치는지 확인합니다. 또한,
     * 시간 순서에 따라 경로가 일치하는지 여부를 검사하고 결과를 반환합니다.
     * </p>
     *
     * @param myId 사용자 ID
     * @param opponentId 상대 사용자 ID
     * @param foundItem 습득물 엔티티
     * @return 경로 겹침 여부와 검증 결과 상태가 포함된 {@link RoutesOverlapResponse}
     */
    public RoutesOverlapResponse verifyRouteOverlap(int myId, int opponentId, FoundItem foundItem) {
        int finderId = -1;
        int loserId = -1;

        if (isFoundItemOwnedBy(myId, foundItem)) {
            finderId = myId;
            loserId = opponentId;
        } else if (isFoundItemOwnedBy(opponentId, foundItem)) {
            finderId = opponentId;
            loserId = myId;
        } else {
            throw new CustomException(ErrorCode.INVALID_INPUT_VALUE);
        }

        log.info("[경로 검증 사용자 구분] finderId: {}, loserId: {}", finderId, loserId);
        // 1. 습득 날짜 및 위치 조회
        LocalDate foundAt = foundItem.getFoundAt();
        org.locationtech.jts.geom.Point foundPoint = foundItem.getCoordinates();
        org.springframework.data.geo.Point geoPoint = convertToGeoPoint(foundPoint);

        // 2. 습득자가 지나간 여부 및 시간 확인(습득 날짜의 일시 중 가장 이후 시간으로 채택)
        Distance searchDistance = new Distance(MAX_DISTANCE_KILOMETERS, Metrics.KILOMETERS);
        Optional<LocalDateTime> foundTimeOpt = getLatestTimeBetween(finderId, geoPoint, searchDistance, foundAt.atStartOfDay(), foundAt.plusDays(1).atStartOfDay());
        if (foundTimeOpt.isEmpty()) {
            return createResponse(false, VerificationStatus.NO_FINDER_LOCATION);
        }
        log.info("[습득 추정 시간] foundTIme: {}", foundTimeOpt.get());

        // 3. 추정된 습득 시간을 기반으로 분실자가 지나간 여부 및 시간 확인(저장된 모든 일자에 대해 적용)
        LocalDateTime foundTime = foundTimeOpt.get();
        Optional<LocalDateTime> lostTimeOpt = getEarliestTimeBefore(loserId, geoPoint, searchDistance, foundTime);
        if (lostTimeOpt.isEmpty()) {
            return createResponse(false, VerificationStatus.NO_LOSER_LOCATION);
        }
        LocalDateTime lostTime = lostTimeOpt.get();
        log.info("[경로 검증] VERIFIED - 분실 시간: {}, 습득 시간: {}", lostTime, foundTime);

        return createResponse(true, VerificationStatus.VERIFIED);
    }

    private boolean isFoundItemOwnedBy(int userId, FoundItem foundItem) {
        return userId == foundItem.getUser().getId();
    }

    /**
     * JTS 포맷의 좌표를 Spring Data MongoDB의 GeoPoint로 변환합니다.
     *
     * <p>
     * 이 메서드는 {@link org.locationtech.jts.geom.Point} 객체를 {@link org.springframework.data.geo.Point}로 변환하여
     * MongoDB GeoSpatial 쿼리에서 사용할 수 있도록 합니다.
     * </p>
     *
     * @param point JTS 포인트
     * @return 변환된 {@link org.springframework.data.geo.Point}
     */
    private Point convertToGeoPoint(org.locationtech.jts.geom.Point point) {
        return new Point(point.getX(), point.getY());
    }

    /**
     * 사용자 ID 및 위치 기준으로 지정 거리 내에 위치한 데이터를 GeoSpatial 쿼리로 조회합니다.
     *
     * <p>
     * 이 메서드는 주어진 사용자 ID와 위치를 기준으로 지정된 거리 내에 있는 위치 데이터를 조회합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param point 기준 좌표
     * @param distance 최대 거리
     * @param additionalCriteria 추가 필터링 조건 (null 가능)
     * @return 위치 조회 결과 리스트
     */
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

    /**
     * 주어진 시간 범위 내에서 가장 최근의 위치 정보를 반환합니다.
     *
     * <p>
     * 이 메서드는 주어진 시간 범위 내에서 가장 최근에 기록된 위치 정보를 반환합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param point 기준 좌표
     * @param distance 최대 거리
     * @param startTime 조회 시작 시간
     * @param endTime 조회 종료 시간
     * @return 가장 최근 위치의 시간 정보 (Optional)
     */
    private Optional<LocalDateTime> getLatestTimeBetween(int userId, Point point, Distance distance,
                                                         LocalDateTime startTime, LocalDateTime endTime) {
        Criteria timeCriteria = Criteria.where("timestamp").gte(startTime).lt(endTime);

        GeoResults<UserLocation> geoResults = findNearByUserLocation(userId, point, distance, timeCriteria);

        return geoResults.getContent().stream()
                .map(result -> result.getContent().getTimestamp())
                .max(LocalDateTime::compareTo);
    }

    /**
     * 특정 시점 이전에 기록된 가장 이른 위치 정보를 반환합니다.
     *
     * <p>
     * 이 메서드는 주어진 시점 이전에 기록된 가장 이른 위치 정보를 반환합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param point 기준 좌표
     * @param distance 최대 거리
     * @param endTime 조회 종료 시간
     * @return 가장 이른 위치의 시간 정보 (Optional)
     */
    private Optional<LocalDateTime> getEarliestTimeBefore(int userId, Point point, Distance distance, LocalDateTime endTime) {
        Criteria timeCriteria = Criteria.where("timestamp").lt(endTime);

        GeoResults<UserLocation> geoResults = findNearByUserLocation(userId, point, distance, timeCriteria);

        return geoResults.getContent().stream()
                .map(result -> result.getContent().getTimestamp())
                .min(LocalDateTime::compareTo);
    }

    /**
     * 검증 결과를 응답 DTO로 생성합니다.
     *
     * <p>
     * 이 메서드는 경로 겹침 여부 및 검증 상태에 대한 결과를 {@link RoutesOverlapResponse} 형태로 생성하여 반환합니다.
     * </p>
     *
     * @param overlapExists 경로 겹침 여부
     * @param status 검증 상태
     * @return {@link RoutesOverlapResponse}
     */
    private RoutesOverlapResponse createResponse(boolean overlapExists, VerificationStatus status) {
        return new RoutesOverlapResponse(overlapExists, status);
    }
}
