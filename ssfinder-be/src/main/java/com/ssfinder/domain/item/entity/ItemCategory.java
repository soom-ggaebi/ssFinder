package com.ssfinder.domain.item.entity;

import jakarta.persistence.*;
import lombok.*;

/**
 * packageName    : com.ssfinder.domain.item.entity<br>
 * fileName       : ItemCategory.java<br>
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
@Table(name = "item_category")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class ItemCategory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "parent_id", referencedColumnName = "id")
    private ItemCategory itemCategory;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(nullable = false, length = 100)
    private Level level;
}
