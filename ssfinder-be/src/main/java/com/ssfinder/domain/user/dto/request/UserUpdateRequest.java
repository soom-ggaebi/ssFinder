package com.ssfinder.domain.user.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import jakarta.validation.constraints.Size;

/**
 * packageName    : com.ssfinder.domain.user.dto.request<br>
 * fileName       : UserUpdateRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-03-21<br>
 * description    : 사용자 정보 수정을 위한 요청 DTO입니다.<br>
 *                  닉네임과 지역 정보 업데이트를 지원합니다.<br>
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
