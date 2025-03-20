package com.ssfinder.domain.notification.entity;

import com.ssfinder.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.notification.entity<br>
 * fileName       : Notification.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * <br>
 */
@Entity
@Table(name = "notification")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "user_id", referencedColumnName = "id", nullable = false)
    private User user;

    @Column(length = 255, nullable = false)
    private String title;

    @Lob
    @Column(columnDefinition = "TEXT")
    private String body;

    @Column(name = "scheduled_at")
    private LocalDateTime scheduledAt;

    @Column(name = "flag_send", nullable = false)
    private Boolean flagSend;

    @Column(length = 13, nullable = false)
    private String type;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;
}
