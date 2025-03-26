package com.ssfinder.domain.founditem.entity;

import com.ssfinder.domain.item.entity.ItemCategory;
import com.ssfinder.domain.user.entity.User;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.locationtech.jts.geom.Point;

import java.sql.Types;
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
                @Index(name = "idx_coordinates", columnList = "coordinates")
        }
)
@Getter
@Setter
@NoArgsConstructor(access = AccessLevel.PUBLIC)
@AllArgsConstructor
@Builder
public class FoundItem {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne
    @JoinColumn(name = "user_id", referencedColumnName = "id")
    private User user;

    @ManyToOne
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
    private Status status;

    @Lob
    @Column(columnDefinition = "TEXT")
    private String detail;

    @Column(length = 20)
    private String phone;

    @Column(length = 255)
    private String image;

    @Column(name = "management_id", length = 20)
    private String managementId;

    @Column(name = "stored_at", nullable = false, length = 100)
    private String storedAt;

    @JdbcTypeCode(Types.OTHER)
    @Column(name = "coordinates", columnDefinition = "POINT", nullable = false)
    private Point coordinates;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

}
