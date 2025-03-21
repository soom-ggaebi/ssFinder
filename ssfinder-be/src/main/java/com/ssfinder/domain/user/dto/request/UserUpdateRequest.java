package com.ssfinder.domain.user.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.validation.constraints.Size;

/**
 * packageName    : com.ssfinder.domain.user.dto.request<br>
 * fileName       : UserUpdateRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-03-21<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-21          okeio           최초생성<br>
 * <br>
 */

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record UserUpdateRequest (
        @Size(max = 30) String nickname,
        @Size(max = 10) String myRegion
){
}
