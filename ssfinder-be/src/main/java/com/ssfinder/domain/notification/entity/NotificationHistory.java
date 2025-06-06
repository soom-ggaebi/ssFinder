package com.ssfinder.domain.notification.entity;

import com.ssfinder.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.notification.entity<br>
 * fileName       : NotificationHistory.java<br>
 * author         : okeio<br>
 * date           : 2025-04-01<br>
 * description    : 사용자에게 발송된 알림 내역을 저장하는 엔티티입니다.<br>
 *                  알림 제목, 내용, 유형, 발송 시각, 삭제 여부 등을 포함합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-01          okeio           최초생성<br>
 * 2025-04-02          okeio           삭제 여부 필드 추가<br>
 * <br>
 */
@Entity
@Table(name = "notification_history")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
@EntityListeners(AuditingEntityListener.class)
@ToString
public class NotificationHistory {
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

    @Column(length = 13, nullable = false)
    @Enumerated(EnumType.STRING)
    private NotificationType type;

    @Column(name = "send_at", nullable = false)
    @CreatedDate
    private LocalDateTime sendAt;

    @Column(name = "deleted_at")
    private LocalDateTime deletedAt;

    @Column(name = "is_deleted", nullable = false)
    @Builder.Default
    private Boolean isDeleted = false;
}
