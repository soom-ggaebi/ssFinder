package com.ssfinder.domain.lostitem.repository;

import com.ssfinder.domain.lostitem.entity.LostItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.lost.repository<br>
 * fileName       : LostRepository.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * <br>
 */
public interface LostItemRepository extends JpaRepository<LostItem, Integer> {

    @Query("SELECT l FROM LostItem l " +
            "JOIN FETCH l.itemCategory ic " +
            "LEFT JOIN FETCH ic.itemCategory parent " +
            "WHERE l.user.id = :userId")
    List<LostItem> findAllByUserIdWithCategories(@Param("userId") Integer userId);
}
