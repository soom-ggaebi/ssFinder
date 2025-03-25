package com.ssfinder.domain.found.service;

import com.ssfinder.domain.found.entity.FoundItem;
import com.ssfinder.domain.found.entity.Status;
import com.ssfinder.domain.found.repository.FoundRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;

/**
 * packageName    : com.ssfinder.domain.found.service<br>
 * fileName       : FoundService.java<br>
 * author         : joker901010<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          joker901010           최초생성<br>
 * 2025-03-25          okeio                습득일자 및 상태로 조회 메서드 추가<br>
 * <br>
 */
@Slf4j
@Service
@RequiredArgsConstructor
@Transactional
public class FoundService {

    private final FoundRepository foundRepository;

    public List<FoundItem> getStoredItemsFoundDaysAgo(int daysAgo) {
        return foundRepository.findByFoundAtAndStatus(LocalDate.now().minusDays(daysAgo), Status.STORED);
    }

}
