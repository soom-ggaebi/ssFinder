package com.ssfinder.domain.auth.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.user.entity.Gender;
import com.ssfinder.domain.user.entity.User;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.auth.dto.request<br>
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

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record KakaoLoginRequest (
        @NotBlank String name,
        @NotBlank @Email String email,
        @Pattern(regexp = "\\d{4}") String birthyear,
        @Pattern(regexp = "\\d{4}") String birthday,
        @NotBlank String gender,
        @NotBlank String providerId
){
    public User toUserEntity() {
        return User.builder()
                .name(name)
                .email(email)
                .birth(LocalDate.of(
                        Integer.parseInt(birthyear),
                        Integer.parseInt(birthday.substring(0, 2)),
                        Integer.parseInt(birthday.substring(2))
                ))
                .gender(Gender.valueOf(gender.toUpperCase()))
                .providerId(providerId)
                .createdAt(LocalDateTime.now())
                .build();
    }
}
