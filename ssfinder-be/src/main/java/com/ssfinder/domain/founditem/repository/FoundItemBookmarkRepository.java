package com.ssfinder.domain.founditem.repository;

import com.ssfinder.domain.founditem.entity.FoundItemBookmark;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.Set;

/**
 * packageName    : com.ssfinder.domain.found.repository<br>
 * fileName       : FoundItemBookmarkRepository.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-26<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-26          joker901010           최초생성<br>
 * <br>
 */
public interface FoundItemBookmarkRepository extends JpaRepository<FoundItemBookmark, Integer> {

    List<FoundItemBookmark> findByUserId(Integer userId);

    Optional<FoundItemBookmark> findByUserIdAndFoundItemId(Integer userId, Integer foundItemId);

    boolean existsByUserIdAndFoundItemId(Integer userId, Integer foundItemId);

    void deleteByFoundItemId(Integer foundItemId);

    @Query("SELECT f.foundItem.id FROM FoundItemBookmark f WHERE f.user.id = :userId AND f.foundItem.id IN :itemIds")
    Set<Integer> findBookmarkedItemIds(@Param("userId") Integer userId, @Param("itemIds") List<Integer> itemIds);
}
