package com.ssfinder.domain.lostitem.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class LostItemUpdateResponse {

    private Integer id;

    private Integer itemCategoryId;

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
