package com.ssfinder.domain.found.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;

/**
 * packageName    : com.ssfinder.domain.found.dto.request<br>
 * fileName       : FoundItemRegisterRequest.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-23<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-21          joker901010           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class FoundItemRegisterRequest {
    @JsonProperty("item_category_id")
    private Integer itemCategoryId;

    private String name;

    @JsonProperty("found_at")
    private LocalDate foundAt;

    private String location;

    private String color;

    private String status;

    private String detail;

    private String phone;

    private String image;

    @JsonProperty("stored_at")
    private String storedAt;
}
