package com.ssfinder.domain.item.entity;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.lostitem.entity.LostItem;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.item.entity<br>
 * fileName       : MatchedItem.java<br>
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
@Table(name = "matched_item")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class MatchedItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "lost_item_id", referencedColumnName = "id", nullable = false)
    private LostItem lostItem;

    @ManyToOne
    @JoinColumn(name = "found_item_id", referencedColumnName = "id", nullable = false)
    private FoundItem foundItem;

    @Column(nullable = false)
    private Integer score;

    @Column(name = "matched_at", nullable = false)
    private LocalDateTime matchedAt;
}
