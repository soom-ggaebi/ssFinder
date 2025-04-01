package com.ssfinder.domain.auth.dto.request;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import com.ssfinder.domain.user.entity.Gender;
import com.ssfinder.domain.user.entity.User;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.extern.slf4j.Slf4j;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * packageName    : com.ssfinder.domain.auth.dto.request<br>
 * fileName       : KakaoLoginRequest.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * 2025-04-01          okeio           nullable 가능한 필드 처리<br>
 * <br>
 */

@Slf4j
@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
public record KakaoLoginRequest (
        String name,
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
        User.UserBuilder builder = User.builder()
                .nickname(profileNickname)
                .email(email)
                .providerId(providerId)
                .phone(phoneNumber)
                .gender(Gender.from(gender))
                .createdAt(LocalDateTime.now());

        if (Objects.nonNull(name)) {
            builder.name(name);
        }

        if (Objects.nonNull(birthyear) && Objects.nonNull(birthday)) {
            try {
                LocalDate birthDate = LocalDate.of(
                        Integer.parseInt(birthyear),
                        Integer.parseInt(birthday.substring(0, 2)),
                        Integer.parseInt(birthday.substring(2))
                );
                builder.birth(birthDate);
            } catch (NumberFormatException | IndexOutOfBoundsException e) {
                log.warn("[로그인] 부적절한 생일 필드 요청");
            }
        }

        return builder.build();
    }
}
