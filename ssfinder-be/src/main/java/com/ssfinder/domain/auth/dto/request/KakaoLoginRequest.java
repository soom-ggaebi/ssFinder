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
        @NotBlank String profileNickname,
        @NotBlank @Email String email,
        @Pattern(regexp = "\\d{4}") String birthyear,
        @Pattern(regexp = "\\d{4}") String birthday,
        String gender,
        @NotBlank String phoneNumber,
        @NotBlank String providerId,
        @NotBlank String fcmToken
){
    public User toUserEntity() {
        return User.builder()
                .name(name)
                .nickname(profileNickname)
                .email(email)
                .birth(LocalDate.of(
                        Integer.parseInt(birthyear),
                        Integer.parseInt(birthday.substring(0, 2)),
                        Integer.parseInt(birthday.substring(2))
                ))
                .gender(Gender.from(gender))
                .providerId(providerId)
                .phone(phoneNumber)
                .createdAt(LocalDateTime.now())
                .build();
    }
}
