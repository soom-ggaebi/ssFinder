package com.ssfinder.domain.chat.entity;

import com.ssfinder.domain.founditem.entity.FoundItem;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.chat.entity<br>
 * fileName       : ChatRoom.java<br>
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
@Table(name = "chat_room")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class ChatRoom {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "found_item_id", referencedColumnName = "id", nullable = false)
    private FoundItem foundItem;

    @Column(name = "latest_sent_at")
    private LocalDateTime latestSentAt;

    @Column(name = "latest_message")
    private String latestMessage;
}
