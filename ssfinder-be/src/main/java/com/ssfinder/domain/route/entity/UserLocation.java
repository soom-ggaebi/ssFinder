package com.ssfinder.domain.route.entity;

import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.index.*;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.route.entity<br>
 * fileName       : UserLocation.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 사용자의 위치 정보를 저장하는 MongoDB 도큐먼트 엔티티입니다.<br>
 *                  위치 좌표, 이벤트 유형, 생성 시간 등을 포함하며, 7일 후 자동 삭제됩니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * 2025-04-07          okeio           7일 후 삭제, ttl 옵션 추가<br>
 * <br>
 */
@Document(collection = "user_location")
@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class UserLocation {

    @Id
    private String id;

    @Field("user_id")
    private Integer userId;

    @Indexed(expireAfter = "7d")
    private LocalDateTime timestamp;

    @GeoSpatialIndexed(type = GeoSpatialIndexType.GEO_2DSPHERE)
    private GeoJsonPoint location;

    @Field("event_type")
    private String eventType;

    @Field("event_timestamp")
    private LocalDateTime eventTimestamp;
}
