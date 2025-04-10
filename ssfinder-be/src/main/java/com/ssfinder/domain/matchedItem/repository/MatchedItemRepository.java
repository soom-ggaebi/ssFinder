package com.ssfinder.domain.matchedItem.repository;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.lostitem.entity.LostItem;
import com.ssfinder.domain.matchedItem.entity.MatchedItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
/**
 * packageName    : com.ssfinder.domain.matchedItem.repository<br>
 * fileName       : MatchedItemRepository.java<br>
 * author         : sonseohy<br>
 * date           : 2025-04-09<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-09          sonseohy           최초생성<br>
 * <br>
 */
@Repository
public interface MatchedItemRepository extends JpaRepository<MatchedItem, Integer> {
    boolean existsByLostItemAndFoundItem(LostItem lostItem, FoundItem foundItem);
    List<MatchedItem> findByLostItemOrderByScoreDesc(LostItem lostItem);

    @Query(value = "SELECT sub.lost_item_id, sub.found_item_image " +
            "FROM ( " +
            "  SELECT mi.lost_item_id, fi.image AS found_item_image, " +
            "         ROW_NUMBER() OVER (PARTITION BY mi.lost_item_id ORDER BY mi.score DESC) AS rn " +
            "  FROM matched_item mi " +
            "  JOIN found_item fi ON mi.found_item_id = fi.id " +
            ") sub " +
            "WHERE sub.rn <= 3", nativeQuery = true)
    List<Object[]> findTop3FoundImagesPerLostItem();
}