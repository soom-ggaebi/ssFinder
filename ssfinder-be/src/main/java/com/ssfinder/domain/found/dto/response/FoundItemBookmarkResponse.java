package com.ssfinder.domain.found.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public class FoundItemBookmarkResponse {
    private Integer id;

    @JsonProperty("user_id")
    private Integer userId;

    @JsonProperty("found_item_id")
    private Integer foundItemId;
}