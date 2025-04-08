package com.ssfinder.domain.route.dto.mapper;

import com.ssfinder.domain.route.dto.request.LocationTrace;
import com.ssfinder.domain.route.dto.request.RouteCreateRequest;
import com.ssfinder.domain.route.dto.response.RoutesGetResponse;
import com.ssfinder.domain.route.entity.UserLocation;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.springframework.data.mongodb.core.geo.GeoJsonPoint;

import java.util.*;
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

    @Mapping(target = "longitude", expression = "java(userLocation.getLocation().getX())")
    @Mapping(target = "latitude", expression = "java(userLocation.getLocation().getY())")
    LocationTrace toLocationTrace(UserLocation userLocation);

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

    default GeoJsonPoint toGeoJsonPoint(LocationTrace trace) {
        if (Objects.isNull(trace)|| Objects.isNull(trace.getLatitude()) || Objects.isNull(trace.getLongitude())) {
            return null;
        }
        return new GeoJsonPoint(trace.getLongitude(), trace.getLatitude());
    }

    default RoutesGetResponse toRoutesGetResponse(List<UserLocation> userLocations) {
        List<LocationTrace> list = userLocations.stream()
                .map(this::toLocationTrace)
                .collect(Collectors.toList());

        return new RoutesGetResponse(list);
    }

}
