package com.ssfinder.domain.lostitem.dto.response;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.validation.constraints.Size;
import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import lombok.Singular;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * packageName    : com.ssfinder.domain.lostitem.dto.response<br>
 * fileName       : LostItemListResponse.java<br>
 * author         : joker901010<br>
 * date           : 2025-04-10<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-10          joker901010           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@JsonInclude(JsonInclude.Include.NON_NULL)
@Getter
@Setter
@Builder
public class LostItemListResponse {

    private int id;

    private Integer userId;

    private String majorItemCategory;

    private String minorItemCategory;

    private String title;

    private String color;

    private LocalDate lostAt;

    private String location;

    private String image;

    private String status;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    private Boolean notificationEnabled;

    @Size(max = 3)
    private List<String> matchedImageUrls;
}
