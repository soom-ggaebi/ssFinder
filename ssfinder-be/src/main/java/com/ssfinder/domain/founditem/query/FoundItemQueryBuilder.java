package com.ssfinder.domain.founditem.query;


import com.ssfinder.domain.founditem.dto.request.FoundItemFilterRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemViewportRequest;

/**
 * packageName    : com.ssfinder.domain.found.query<br>
 * fileName       : FoundItemQueryBuilder.java<br>
 * author         : leeyj<br>
 * date           : 2025-04-07<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-07          leeyj           최초생성<br>
 * <br>
 */
public class FoundItemQueryBuilder {

    // 뷰포트 기반 쿼리 생성
    public static String buildViewportQuery(FoundItemViewportRequest request) {
        return String.format(
                "{\"bool\": {"
                        + "\"filter\": {"
                        + "\"geo_bounding_box\": {"
                        + "\"location_geo\": {"
                        + "\"top_left\": {\"lat\": %f, \"lon\": %f},"
                        + "\"bottom_right\": {\"lat\": %f, \"lon\": %f}"
                        + "}"
                        + "}"
                        + "},"
                        + "\"must_not\": {"
                        + "\"bool\": {"
                        + "\"must\": ["
                        + "{\"term\": {\"latitude\": 0.0}},"
                        + "{\"term\": {\"longitude\": 0.0}}"
                        + "]"
                        + "}"
                        + "}"
                        + "}}",
                request.getMaxLatitude(), request.getMinLongitude(),
                request.getMinLatitude(), request.getMaxLongitude()
        );
    }


    // 필터링 기반 쿼리 생성
    public static String buildFilterQuery(FoundItemFilterRequest request) {
        StringBuilder mustFilters = new StringBuilder();
        mustFilters.append("[");
        mustFilters.append(String.format(
                "{\"geo_bounding_box\": {\"location_geo\": {\"top_left\": {\"lat\": %f, \"lon\": %f}, \"bottom_right\": {\"lat\": %f, \"lon\": %f}}}}",
                request.getMaxLatitude(), request.getMinLongitude(),
                request.getMinLatitude(), request.getMaxLongitude()
        ));
        if (request.getStatus() != null && !request.getStatus().equalsIgnoreCase("all")) {
            mustFilters.append(",{\"term\": {\"status\": \"").append(request.getStatus()).append("\"}}");
        }
        if (request.getType() != null && !request.getType().equalsIgnoreCase("전체")) {
            mustFilters.append(",");
            if (request.getType().equals("숨숨파인더")) {
                mustFilters.append("{\"bool\": {\"must_not\": {\"exists\": {\"field\": \"management_id\"}}}}");
            } else if (request.getType().equals("경찰청")) {
                mustFilters.append("{\"exists\": {\"field\": \"management_id\"}}");
            }
        }
        if (request.getStoredAt() != null && !request.getStoredAt().isEmpty()) {
            mustFilters.append(",{\"term\": {\"stored_at\": \"").append(request.getStoredAt()).append("\"}}");
        }
        if (request.getFoundAt() != null) {
            mustFilters.append(",{\"term\": {\"found_at\": \"").append(request.getFoundAt().toString()).append("\"}}");
        }
        if (request.getMajorCategory() != null && !request.getMajorCategory().isEmpty()) {
            mustFilters.append(",{\"term\": {\"category_major\": \"").append(request.getMajorCategory()).append("\"}}");
        }
        if (request.getMinorCategory() != null && !request.getMinorCategory().isEmpty()) {
            mustFilters.append(",{\"term\": {\"category_minor\": \"").append(request.getMinorCategory()).append("\"}}");
        }
        if (request.getColor() != null && !request.getColor().isEmpty()) {
            mustFilters.append(",{\"term\": {\"color\": \"").append(request.getColor()).append("\"}}");
        }
        mustFilters.append("]");
        return String.format("{\"bool\": {\"must\": %s}}", mustFilters.toString());
    }
}