package com.ssfinder.domain.route.repository;

import com.ssfinder.domain.route.entity.UserLocation;
import org.springframework.data.mongodb.repository.MongoRepository;

import java.time.LocalDateTime;
import java.util.List;

/**
 * packageName    : com.ssfinder.domain.route.repository<br>
 * fileName       : UserLocationRepository.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 사용자 위치 정보를 MongoDB에서 조회 및 관리하는 리포지토리 인터페이스입니다.<br>
 *                  특정 사용자 ID와 시간 범위에 따라 위치 데이터를 조회할 수 있습니다.<br>
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
}