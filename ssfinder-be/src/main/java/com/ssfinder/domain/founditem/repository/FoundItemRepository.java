package com.ssfinder.domain.founditem.repository;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

/**
 * packageName    : com.ssfinder.domain.found.repository<br>
 * fileName       : FoundRepository.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * <br>
 */
public interface FoundItemRepository extends JpaRepository<FoundItem, Integer> {
    List<FoundItem> findAllByUserId(int userId);

    @Query(value = "SELECT * FROM found_item " +
            "WHERE MBRContains(ST_MakeEnvelope(:minLon, :minLat, :maxLon, :maxLat), coordinates) = 1",
            nativeQuery = true)
    List<FoundItem> findByCoordinatesWithin(@Param("minLat") double minLat,
                                            @Param("minLon") double minLon,
                                            @Param("maxLat") double maxLat,
                                            @Param("maxLon") double maxLon);

    List<FoundItem> findByFoundAtAndStatus(LocalDate date, FoundItemStatus foundItemStatus);
}
