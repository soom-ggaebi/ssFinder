package com.ssfinder.domain.matchedItem.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@Builder
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class MatchedItemsTopFiveResponse {

    private Integer id;

    private String image;

    private String majorCategory;

    private String minorCategory;

    private String name;

    private String type;

    private String location;

    private String storedAt;

    private String status;

    private LocalDateTime createdAt;

    private Integer score;

}
