package com.ssfinder.domain.lostitem.entity;

import com.ssfinder.domain.itemcategory.entity.ItemCategory;
import com.ssfinder.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import org.locationtech.jts.geom.Point;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * packageName    : com.ssfinder.domain.lost.entity<br>
 * fileName       : LostItem.java<br>
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
@Table(name = "lost_item")
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor
@Builder
public class LostItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "user_id", referencedColumnName = "id", nullable = false)
    private User user;

    @ManyToOne
    @JoinColumn(name = "item_category_id", referencedColumnName = "id", nullable = false)
    private ItemCategory itemCategory;

    @Column(length = 100, nullable = false)
    private String title;

    @Column(length = 20, nullable = false)
    private String color;

    @Column(name = "lost_at", nullable = false)
    private LocalDate lostAt;

    @Column(length = 100, nullable = false)
    private String location;

    @Lob
    @Column(columnDefinition = "TEXT")
    private String detail;

    @Column(length = 255)
    private String image;

    @Column(length = 5, nullable = false)
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private LostItemStatus status = LostItemStatus.LOST;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @JdbcTypeCode(SqlTypes.GEOMETRY)
    @Column(name = "coordinates", columnDefinition = "POINT SRID 4326")
    private Point coordinates;

    @Column(name = "notification_enabled", nullable = false)
    @Builder.Default
    private Boolean notificationEnabled = true;
}
