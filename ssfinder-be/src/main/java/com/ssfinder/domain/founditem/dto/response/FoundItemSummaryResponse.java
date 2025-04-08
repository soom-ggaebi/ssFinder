package com.ssfinder.domain.founditem.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.found.dto.response<br>
 * fileName       : FoundItemSummaryResponse.java<br>
 * author         : joker901010<br>
 * date           : 2025-04-05<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-05          joker901010           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class FoundItemSummaryResponse {

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

    private Boolean bookmarked;
}
