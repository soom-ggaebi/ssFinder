package com.ssfinder.domain.founditem.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.found.dto.request<br>
 * fileName       : FoundItemDocumentDetailResponse.java<br>
 * author         : joker901010<br>
 * date           : 2025-04-02<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-02          joker901010           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class FoundItemDocumentDetailResponse {

    private String id;

    private String userId;

    private String majorCategory;

    private String minorCategory;

    private String name;

    private LocalDate foundAt;

    private String location;

    private String color;

    private String status;

    private String phone;

    private String detail;

    private String image;

    private String storedAt;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    private Double latitude;

    private Double longitude;

    private Boolean type;

}
