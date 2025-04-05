package com.ssfinder.domain.chat.entity;

import com.ssfinder.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.chat.entity<br>
 * fileName       : UserChatRoom.java<br>
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
@Table(name = "chat_room_participant")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class ChatRoomParticipant {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "user_id", referencedColumnName = "id", nullable = false)
    private User user;

    @ManyToOne
    @JoinColumn(name = "chat_room_id", referencedColumnName = "id", nullable = false)
    private ChatRoom chatRoom;

    @Column(name = "created_at", nullable = false)
    @CreationTimestamp
    private LocalDateTime createdAt;

    @Column(name = "left_at")
    private LocalDateTime leftAt;

    @Column(name = "recreated_at")
    private LocalDateTime recreatedAt;

    @Column(length = 8, nullable = false)
    @Enumerated(EnumType.STRING)
    private ChatRoomStatus status;

    // mongodb id 값 참조 - 추후 수정 필요하면 수정
    @Column(name = "latest_read_message_id")
    private String latestReadMessageId;

    @Column(name = "notification_enabled", nullable = false)
    @Builder.Default
    private Boolean notificationEnabled = true;
}
