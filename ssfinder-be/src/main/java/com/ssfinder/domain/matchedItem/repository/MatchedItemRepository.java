package com.ssfinder.domain.matchedItem.repository;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.itemcategory.dto.MatchedItemsTopFiveProjection;
import com.ssfinder.domain.lostitem.entity.LostItem;
import com.ssfinder.domain.matchedItem.entity.MatchedItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
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

    @Query(value = """
        SELECT 
          f.id                            AS id,
          f.image                         AS image,
          CASE 
            WHEN c.level = 'MAJOR' THEN c.name 
            ELSE pc.name 
          END                             AS major_category,
          CASE 
            WHEN c.level = 'MINOR' THEN c.name 
            ELSE NULL 
          END                             AS minor_category,
          f.name                          AS name,
          CASE 
            WHEN f.management_id IS NULL OR f.management_id = '' THEN '숨숨파인더' 
            ELSE '경찰청' 
          END                             AS type,
          f.location                      AS location,
          f.stored_at                     AS stored_at,
          f.status                        AS status,
          f.created_at                    AS created_at,
          m.score                         AS score
        FROM matched_item m
        JOIN found_item f     ON m.found_item_id   = f.id
        JOIN item_category c  ON f.item_category_id= c.id
        LEFT JOIN item_category pc ON c.parent_id = pc.id
        WHERE m.lost_item_id = :lostItemId
        ORDER BY m.score DESC
        LIMIT 5
        """,
            nativeQuery = true)
    List<MatchedItemsTopFiveProjection> findTop5MatchedItemsNative(@Param("lostItemId") Integer lostItemId);
}