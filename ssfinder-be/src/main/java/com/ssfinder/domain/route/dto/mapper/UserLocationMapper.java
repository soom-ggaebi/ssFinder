package com.ssfinder.domain.route.dto.mapper;

import com.ssfinder.domain.route.dto.request.LocationTrace;
import com.ssfinder.domain.route.dto.request.RouteCreateRequest;
import com.ssfinder.domain.route.dto.response.RoutesGetResponse;
import com.ssfinder.domain.route.entity.UserLocation;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * packageName    : com.ssfinder.domain.route.dto.mapper<br>
 * fileName       : UserLocationMapper.java<br>
 * author         : okeio<br>
 * date           : 2025-03-28<br>
 * description    : UserLocation entity 의 MapStruct 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-28          okeio           최초생성<br>
 * <br>
 */
@Mapper(componentModel = "spring")
public interface UserLocationMapper {

    @Mapping(target = "timestamp", source = "trace.timestamp")
    @Mapping(target = "location", expression = "java(toGeoJsonPoint(trace))")
    @Mapping(target = "eventType", source = "request.eventType")
    @Mapping(target = "eventTimestamp", source = "request.eventTimestamp")
    UserLocation toUserLocation(RouteCreateRequest request, LocationTrace trace);

    default List<UserLocation> toUserLocations(RouteCreateRequest request, int userId) {
        if (request.route() == null) {
            return Collections.emptyList();
        }
        return request.route().stream()
                .map(trace -> {
                    UserLocation userLocation = toUserLocation(request, trace);
                    userLocation.setUserId(userId);
                    return userLocation;
                })
                .collect(Collectors.toList());
    }

    // 위도/경도 → Point 변환(x=lon, y=lat)
    default GeoJsonPoint toGeoJsonPoint(LocationTrace trace) {
        if (trace == null || trace.getLatitude() == null || trace.getLongitude() == null) {
            return null;
        }
        return new GeoJsonPoint(trace.getLongitude(), trace.getLatitude());
    }

    default RoutesGetResponse toRoutesGetResponse(List<UserLocation> userLocations) {
        // 1. 그룹핑
        Map<GroupKey, List<UserLocation>> grouped = userLocations.stream()
                .collect(Collectors.groupingBy(loc -> new GroupKey(loc.getEventType(), loc.getEventTimestamp())));

        List<RouteCreateRequest> routeCreateRequests = grouped.entrySet().stream()
                .map(entry -> {
                    GroupKey key = entry.getKey();
                    List<LocationTrace> traces = entry.getValue().stream()
                            .sorted(Comparator.comparing(UserLocation::getTimestamp))
                            .map(this::toLocationTrace)
                            .collect(Collectors.toList());

                    return new RouteCreateRequest(key.eventType(), key.eventTimestamp(), traces);
                })
                .collect(Collectors.toList());

        return new RoutesGetResponse(routeCreateRequests);
    }

    default LocationTrace toLocationTrace(UserLocation location) {
        GeoJsonPoint geoJson = location.getLocation();
        return new LocationTrace(
                location.getTimestamp(),
                geoJson.getX(), // latitude
                geoJson.getY() // longitude
        );
    }

    // 내부 그룹 키 클래스 (eventType + eventTimestamp로 그룹핑)
    record GroupKey(String eventType, LocalDateTime eventTimestamp) {}
}
