package com.ssfinder.domain.aimatching.repository;

import com.ssfinder.domain.aimatching.entity.MatchedItem;
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
    // 분실물 ID로 매칭된 항목 조회
    List<MatchedItem> findByLostItemIdOrderByScoreDesc(Integer lostItemId);

    // 분실물 ID와 습득물 ID로 매칭 여부 확인
    boolean existsByLostItemIdAndFoundItemId(Integer lostItemId, Integer foundItemId);
}