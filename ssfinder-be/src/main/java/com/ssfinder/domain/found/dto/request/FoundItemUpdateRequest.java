package com.ssfinder.domain.found.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class FoundItemUpdateRequest {
    @JsonProperty("item_category_id")
    private Integer itemCategoryId;

    private String name;

    @JsonProperty("found_at")
    private LocalDate foundAt;

    private String location;

    private String color;

    private String status;

    private String detail;

    private String image;

    @JsonProperty("stored_at")
    private String storedAt;
}
