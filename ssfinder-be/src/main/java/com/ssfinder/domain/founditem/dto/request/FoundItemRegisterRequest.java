package com.ssfinder.domain.founditem.dto.request;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
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

    @NotBlank
    private Integer itemCategoryId;

    @Size(max = 100)
    @NotBlank
    private String name;

    @NotBlank
    private LocalDate foundAt;

    @Size(max = 100)
    @NotBlank
    private String location;

    @Size(max = 20)
    @NotBlank
    private String color;

    @Size(max = 11)
    private String status;

    @Size(max = 255)
    private String image;

    @Size(max = 5000)
    @NotBlank
    private String detail;

    private String phone;

    @Size(max = 100)
    @NotBlank
    private String storedAt;

    @DecimalMin(value = "-90.0", inclusive = true)
    @DecimalMax(value = "90.0", inclusive = true)
    private Double latitude;

    @DecimalMin(value = "-180.0", inclusive = true)
    @DecimalMax(value = "180.0", inclusive = true)
    private Double longitude;
}
