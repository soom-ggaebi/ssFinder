package com.ssfinder.domain.lostitem.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.*;

import java.time.LocalDate;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class LostItemUpdateRequest {

    private Integer itemCategoryId;

    private String title;

    private String color;

    private LocalDate lostAt;

    private String location;

    private String detail;

    private String image;

    private Double latitude;

    private Double longitude;
}