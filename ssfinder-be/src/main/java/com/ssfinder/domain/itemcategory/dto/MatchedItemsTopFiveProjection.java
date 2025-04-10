package com.ssfinder.domain.itemcategory.dto;

import java.time.LocalDateTime;

public interface MatchedItemsTopFiveProjection {
    Integer getId();
    String getImage();
    String getMajorCategory();
    String getMinorCategory();
    String getName();
    String getType();
    String getLocation();
    String getStoredAt();
    String getStatus();
    LocalDateTime getCreatedAt();
    Integer getScore();
}