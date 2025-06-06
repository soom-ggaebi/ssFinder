package com.ssfinder.domain.founditem.entity;

import com.ssfinder.domain.itemcategory.entity.ItemCategory;
import com.ssfinder.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.OnDelete;
import org.hibernate.annotations.OnDeleteAction;
import org.hibernate.type.SqlTypes;
import org.locationtech.jts.geom.Point;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.found.entity<br>
 * fileName       : FoundItem.java<br>
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
@Table(
        name = "found_item",
        indexes = {
                @Index(name = "idx_found_user_id", columnList = "user_id"),
                @Index(name = "idx_found_item_category_id", columnList = "item_category_id"),
                @Index(name = "idx_found_found_at", columnList = "found_at")
        }
)
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PUBLIC)
@AllArgsConstructor
@Builder
@ToString
public class FoundItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "user_id", referencedColumnName = "id")
    private User user;

    @ManyToOne
    @OnDelete(action = OnDeleteAction.CASCADE)
    @JoinColumn(name = "item_category_id", referencedColumnName = "id", nullable = false)
    private ItemCategory itemCategory;

    @Column(nullable = false, length = 100)
    private String name;

    @Column(name = "found_at", nullable = false)
    private LocalDate foundAt;

    @Column(nullable = false, length = 100)
    private String location;

    @Column(nullable = false, length = 20)
    private String color;

    @Column(nullable = false, length = 11)
    @Enumerated(EnumType.STRING)
    private FoundItemStatus status;

    @Lob
    @Column(columnDefinition = "TEXT")
    private String detail;

    @Column(length = 20)
    private String phone;

    @Column(length = 255)
    private String image;

    @Column(name = "management_id", length = 30)
    private String managementId;

    @Column(name = "stored_at", length = 100)
    private String storedAt;

    @JdbcTypeCode(SqlTypes.GEOMETRY)
    @Column(name = "coordinates", columnDefinition = "POINT SRID 4326")
    private Point coordinates;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

}
