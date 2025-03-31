package com.ssfinder.domain.itemcategory.repository;

import com.ssfinder.domain.itemcategory.entity.ItemCategory;
import com.ssfinder.domain.itemcategory.entity.Level;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.item.repository<br>
 * fileName       : ItemCategoryRepository.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-23<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * <br>
 */
public interface ItemCategoryRepository extends JpaRepository<ItemCategory, Integer> {
    Optional<ItemCategory> findByNameAndLevel(String name, Level level);
}
