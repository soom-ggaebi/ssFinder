package com.ssfinder.domain.lostitem.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.user.entity.User;
import lombok.Builder;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.user.dto.response<br>
 * fileName       : UserGetResponse.java<br>
 * author         : okeio<br>
 * date           : 2025-03-23<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-21          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Builder
public class LostItemResponse {
    private int id;
    private User user;
    private int itemCategoryId;
    private String title;
    private String color;
    private LocalDate lostAt;
    private String location;
    private String detail;
    private String image;
    private String status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Double latitude;
    private Double longitude;
}
