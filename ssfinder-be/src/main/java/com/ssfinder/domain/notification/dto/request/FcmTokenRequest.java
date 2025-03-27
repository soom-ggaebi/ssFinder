package com.ssfinder.domain.notification.dto.request;

import jakarta.validation.constraints.NotBlank;
import org.hibernate.validator.constraints.Length;

/**
 * packageName    : com.ssfinder.domain.notification.dto<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-24<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio           최초생성<br>
 * <br>
 */
public record FcmTokenRequest(
        @NotBlank @Length(min = 1, max = 255) String token
) { }
