package com.ssfinder.domain.route.repository;

import com.ssfinder.domain.route.entity.UserLocation;
import org.springframework.data.geo.Distance;
import org.springframework.data.geo.GeoResults;
import org.springframework.data.geo.Point;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * packageName    : com.ssfinder.domain.route.repository<br>
 * fileName       : UserLocationRepository.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : UserLocation entity 의 Repository 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * <br>
 */
public interface UserLocationRepository extends MongoRepository<UserLocation, String> {
    List<UserLocation> findByUserIdAndTimestampBetween(
            Integer userId,
            LocalDateTime startOfDay,
            LocalDateTime endOfDay
    );

    GeoResults<UserLocation> findByUserIdAndLocationNear(Integer userId, Point location, Distance distance);
}