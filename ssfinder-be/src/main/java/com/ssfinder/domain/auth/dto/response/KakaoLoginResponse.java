package com.ssfinder.domain.auth.dto.response;

/**
 * packageName    : com.ssfinder.domain.auth.dto.response<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * <br>
 */

public record KakaoLoginResponse (
        String accessToken,
        String refreshToken,
        Integer expiresIn
){


}
