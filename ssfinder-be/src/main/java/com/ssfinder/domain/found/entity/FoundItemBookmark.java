package com.ssfinder.domain.found.entity;

import com.ssfinder.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;

/**
 * packageName    : com.ssfinder.domain.found.entity<br>
 * fileName       : FoundItemBookmark.java<br>
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
@Table(name = "found_item_bookmark")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class FoundItemBookmark {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "user_id", referencedColumnName = "id", nullable = false)
    private User user;

    @ManyToOne
    @JoinColumn(name = "found_item_id", referencedColumnName = "id", nullable = false)
    private FoundItem foundItem;
}
