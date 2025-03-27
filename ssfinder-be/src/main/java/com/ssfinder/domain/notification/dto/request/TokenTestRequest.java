package com.ssfinder.domain.notification.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.validation.constraints.NotNull;

/**
 * packageName    : com.ssfinder.domain.notification.dto.request<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * <br>
 */
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record TokenTestRequest(
        @NotNull Integer senderId,
        @NotNull String message
) { }