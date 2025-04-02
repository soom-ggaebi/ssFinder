package com.ssfinder.domain.founditem.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class FoundItemTestResponse {
    private Integer id;

    private String name;

    private LocalDate foundAt;

    private String location;

    private String color;

    private String status;

    private String detail;

    private String image;

    private String storedAt;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;

    private Double latitude;

    private Double longitude;

    private String majorCategory;

    private String minorCategory;
}
