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
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
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

    @Column(nullable = false)
    private String name;

    @Column(nullable = false)
    private String nickname;

    @Column(nullable = false)
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
}
