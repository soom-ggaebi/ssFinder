package com.ssfinder.domain.founditem.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.validation.constraints.*;
import lombok.Getter;
import lombok.Setter;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;

/**
 * packageName    : com.ssfinder.domain.found.dto.request<br>
 * fileName       : FoundItemUpdateRequest.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-26<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-26          joker901010           최초생성<br>
 * 2025-03-27          joker901010           이미지 타입 수정<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class FoundItemUpdateRequest {

    @NotNull
    private Integer itemCategoryId;

    @Size(max = 100)
    @NotBlank
    private String name;

    @NotNull
    private LocalDate foundAt;

    @Size(max = 100)
    @NotBlank
    private String location;

    @Size(max = 20)
    @NotBlank
    private String color;

    private MultipartFile image;

    @Size(max = 5000)
    @NotBlank
    private String detail;

    @Size(max = 100)
    private String storedAt;

    @DecimalMin(value = "-90.0", inclusive = true)
    @DecimalMax(value = "90.0", inclusive = true)
    private Double latitude;

    @DecimalMin(value = "-180.0", inclusive = true)
    @DecimalMax(value = "180.0", inclusive = true)
    private Double longitude;
}
