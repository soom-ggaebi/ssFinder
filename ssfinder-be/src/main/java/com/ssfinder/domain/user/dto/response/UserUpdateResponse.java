package com.ssfinder.domain.user.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;

/**
 * packageName    : com.ssfinder.domain.user.dto.response<br>
 * fileName       : UserUpdateResponse.java<br>
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
public record UserUpdateResponse(
        Integer id,
        String nickname,
        String myRegion
) {}
