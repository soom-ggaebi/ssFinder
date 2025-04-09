package com.ssfinder.domain.aimatching.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.aimatching.entity<br>
 * fileName       : MatchedItem.java<br>
 * author         : sonseohy<br>
 * date           : 2025-04-09<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-09          sonseohy           최초생성<br>
 * <br>
 */
@Entity
@Table(name = "matched_item")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PUBLIC)
@AllArgsConstructor
@Builder
public class MatchedItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(name = "lost_item_id", nullable = false)
    private Integer lostItemId;

    @Column(name = "found_item_id", nullable = false)
    private Integer foundItemId;

    @Column(name = "score", nullable = false)
    private Integer score;

    @Column(name = "matched_at", nullable = false)
    private LocalDateTime matchedAt;
}