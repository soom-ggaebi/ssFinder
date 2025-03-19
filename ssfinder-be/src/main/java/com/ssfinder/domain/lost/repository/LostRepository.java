package com.ssfinder.domain.lost.repository;

import com.ssfinder.domain.lost.entity.LostItem;
import org.springframework.data.jpa.repository.JpaRepository;

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
public interface LostRepository extends JpaRepository<LostItem, Integer> {
}
