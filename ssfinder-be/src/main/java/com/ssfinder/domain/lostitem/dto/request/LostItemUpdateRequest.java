package com.ssfinder.domain.lostitem.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.validation.constraints.*;
import lombok.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;

/**
 * packageName    : com.ssfinder.domain.lost.dto.request<br>
 * fileName       : LostItemUpdateRequest.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-23<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-21          joker901010           최초생성<br>
 * 2025-03-27          joker901010           코드리뷰 수정<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class LostItemUpdateRequest {

    @NotNull
    private Integer itemCategoryId;

    @NotBlank
    @Size(max = 100)
    private String title;

    @NotBlank
    @Size(max = 20)
    private String color;

    @NotNull
    private LocalDate lostAt;

    @NotBlank
    @Size(max = 100)
    private String location;

    @Size(max = 5000)
    @NotBlank
    private String detail;

    private MultipartFile image;

    @DecimalMin(value = "-90.0", inclusive = true)
    @DecimalMax(value = "90.0", inclusive = true)
    private Double latitude;

    @DecimalMin(value = "-180.0", inclusive = true)
    @DecimalMax(value = "180.0", inclusive = true)
    private Double longitude;
}