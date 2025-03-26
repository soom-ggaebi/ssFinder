package com.ssfinder.domain.founditem.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.found.dto.request<br>
 * fileName       : FoundItemUpdateResponse.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-26<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-26          joker901010           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class FoundItemUpdateResponse {
    private Integer id;

    @JsonProperty("item_category_id")
    private Integer itemCategoryId;

    private String name;

    @JsonProperty("found_at")
    private LocalDate foundAt;

    private String location;

    private String color;

    private String detail;

    private String image;

    @JsonProperty("stored_at")
    private String storedAt;

    @JsonProperty("created_at")
    private LocalDateTime createdAt;

    @JsonProperty("updated_at")
    private LocalDateTime updatedAt;

    private Double latitude;

    private Double longitude;
}
