package com.ssfinder.domain.founditem.repository;

import com.ssfinder.domain.founditem.entity.FoundItem;
import org.springframework.data.jpa.repository.JpaRepository;

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
}
