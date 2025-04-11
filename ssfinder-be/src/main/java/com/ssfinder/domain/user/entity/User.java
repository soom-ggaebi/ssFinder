package com.ssfinder.domain.user.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Email;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.user.entity<br>
 * fileName       : User.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    : 사용자 정보를 나타내는 JPA 엔티티 클래스입니다.<br>
 *                  OAuth 기반 가입 사용자 정보를 저장하며, 닉네임, 이메일, 성별, 전화번호 등 기본 정보를 포함합니다.<br>
 *                  계정 삭제 및 복구 관련 로직도 포함되어 있습니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * 2025-04-01          okeio           일부 필드 nullable 제거<br>
 * <br>
 */
@Entity
@Table(name = "user")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    private String name;

    @Column(nullable = false)
    private String nickname;

    private LocalDate birth;

    @Column(nullable = false, length = 100)
    @Email
    private String email;

    @Column(nullable = false)
    private String phone;

    @Column(nullable = false, length = 6)
    @Enumerated(EnumType.STRING)
    private Gender gender;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @Column(name = "provider_id", nullable = false, unique = true)
    private String providerId;

    @Column(name = "my_region")
    private String myRegion;

    /**
     * 계정 복구 가능 여부를 판단합니다.
     * 삭제된 시점으로부터 30일 이내인 경우 복구 가능으로 간주합니다.
     *
     * @return 복구 가능하면 true, 아니면 false
     */
    public boolean isRecoverable() {
        if (this.deletedAt == null) {
            return false;
        }

        LocalDateTime recoverableUntil = this.deletedAt.plusDays(30);
        return LocalDateTime.now().isBefore(recoverableUntil);
    }

    /**
     * 사용자의 계정을 복구 처리합니다.
     * 복구 가능 상태일 때 deletedAt 값을 null로 초기화합니다.
     */
    public void recover() {
        if (isRecoverable()) {
            this.deletedAt = null;
        }
    }
}
