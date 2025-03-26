package com.ssfinder.domain.lostitem.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.item.entity.Level;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Getter;

import java.time.LocalDate;

/**
 * packageName    : com.ssfinder.domain.lost.dto.request<br>
 * fileName       : LostItemRegisterRequest.java<br>
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
public class LostItemRegisterRequest {

    @NotNull
    private Integer itemCategoryId;

    @NotNull
    @Size(max = 100, message = "Title should be less than 100 characters.")
    private String title;

    @NotNull
    @Size(max = 20, message = "Color should be less than 20 characters.")
    private String color;

    @NotNull
    private LocalDate lostAt;

    @NotNull
    @Size(max = 100)
    private String location;

    @Size(max = 1000)
    private String detail;

    @Size(max = 255)
    private String image;

    private Double latitude;

    private Double longitude;
}