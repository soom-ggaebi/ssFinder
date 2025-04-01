package com.ssfinder.domain.route.entity;

import jakarta.persistence.Id;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;
import org.springframework.data.mongodb.core.index.CompoundIndex;
import org.springframework.data.mongodb.core.index.CompoundIndexes;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexType;
import org.springframework.data.mongodb.core.index.GeoSpatialIndexed;
import org.springframework.data.mongodb.core.mapping.Document;
import org.springframework.data.mongodb.core.mapping.Field;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.route.entity<br>
 * fileName       : UserLocation.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : 회원의 경로를 저장하는 UserLocation entity 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
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

    private LocalDateTime timestamp;

    @GeoSpatialIndexed(type = GeoSpatialIndexType.GEO_2DSPHERE)
    private GeoJsonPoint location;

    @Field("event_type")
    private String eventType;

    @Field("event_timestamp")
    private LocalDateTime eventTimestamp;
}
