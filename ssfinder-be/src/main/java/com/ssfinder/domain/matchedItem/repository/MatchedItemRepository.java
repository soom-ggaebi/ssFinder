package com.ssfinder.domain.matchedItem.repository;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.lostitem.entity.LostItem;
import com.ssfinder.domain.matchedItem.entity.MatchedItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
/**
 * packageName    : com.ssfinder.domain.aimatching.repository<br>
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
}