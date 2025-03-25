package com.ssfinder.domain.found.repository;

import com.ssfinder.domain.found.entity.FoundItem;
import com.ssfinder.domain.found.entity.Status;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

/**
 * packageName    : com.ssfinder.domain.found.repository<br>
 * fileName       : FoundRepository.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    : Found entity의 repository 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * 2025-03-25          okeio                 습득일자 및 상태로 조회 메서드 추가<br>
 * <br>
 */
public interface FoundRepository extends JpaRepository<FoundItem, Integer> {
    List<FoundItem> findByFoundAtAndStatus(LocalDate date, Status status);
}
