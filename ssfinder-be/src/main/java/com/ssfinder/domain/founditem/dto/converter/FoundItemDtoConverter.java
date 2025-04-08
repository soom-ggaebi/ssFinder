package com.ssfinder.domain.founditem.dto.converter;

import com.ssfinder.domain.founditem.dto.response.FoundItemDetailResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemSummaryResponse;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * packageName    : com.ssfinder.domain.found.converter<br>
 * fileName       : FoundItemDtoConverter.java<br>
 * author         : leeyj<br>
 * date           : 2025-04-07<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-07          leeyj           최초생성<br>
 * <br>
 */
public class FoundItemDtoConverter {

    public static FoundItemDetailResponse convertToDetailResponse(FoundItemDocument document) {
        FoundItemDetailResponse response = new FoundItemDetailResponse();
        response.setId(document.getMysqlId() != null ? Integer.valueOf(document.getMysqlId()) : null);
        response.setUserId(document.getUserId() != null ? Integer.valueOf(document.getUserId()) : null);
        response.setMajorCategory(document.getCategoryMajor());
        response.setMinorCategory(document.getCategoryMinor());
        response.setName(document.getName());
        response.setFoundAt(document.getFoundAt() != null
                ? LocalDateTime.parse(document.getFoundAt(), DateTimeFormatter.ISO_LOCAL_DATE_TIME).toLocalDate()
                : null);
        response.setLocation(document.getLocation());
        response.setColor(document.getColor());
        response.setStatus(document.getStatus());
        response.setDetail(document.getDetail());
        response.setImage(document.getImage());
        response.setStoredAt(document.getStoredAt());
        response.setCreatedAt(LocalDateTime.now());
        response.setUpdatedAt(LocalDateTime.now());
        response.setLatitude(document.getLatitude());
        response.setLongitude(document.getLongitude());
        return response;
    }

    public static FoundItemSummaryResponse convertToSummaryResponse(FoundItemDocument document) {
        FoundItemSummaryResponse response = new FoundItemSummaryResponse();
        response.setId(document.getMysqlId() != null ? Integer.valueOf(document.getMysqlId()) : null);
        response.setImage(document.getImage());
        response.setMajorCategory(document.getCategoryMajor());
        response.setMinorCategory(document.getCategoryMinor());
        response.setName(document.getName());
        response.setLocation(document.getLocation());
        response.setType(document.getManagementId() != null ? "경찰청" : "숨숨파인더");
        response.setStatus(document.getStatus());

        if (document.getStoredAt() != null) {
            response.setStoredAt(document.getStoredAt());
        }

        if (document.getCreatedAt() != null) {
            try {
                response.setCreatedAt(LocalDateTime.parse(document.getCreatedAt()));
            } catch (Exception e) {
                response.setCreatedAt(LocalDateTime.now());
            }
        } else {
            response.setCreatedAt(LocalDateTime.now());
        }

        response.setBookmarked(false);
        return response;
    }
}