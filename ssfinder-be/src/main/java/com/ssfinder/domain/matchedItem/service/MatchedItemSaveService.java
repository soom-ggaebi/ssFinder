package com.ssfinder.domain.matchedItem.service;

import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.repository.FoundItemRepository;
import com.ssfinder.domain.lostitem.entity.LostItem;
import com.ssfinder.domain.lostitem.repository.LostItemRepository;
import com.ssfinder.domain.matchedItem.dto.response.MatchedItemResponse;
import com.ssfinder.domain.matchedItem.entity.MatchedItem;
import com.ssfinder.domain.matchedItem.event.MatchedItemEvent;
import com.ssfinder.domain.matchedItem.repository.MatchedItemRepository;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * packageName    : com.ssfinder.domain.matchedItem.service<br>
 * fileName       : MatchedItemSaveService.java<br>
 * author         : okeio<br>
 * date           : 2025-04-11<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-11          okeio           최초생성<br>
 * <br>
 */
@Slf4j
@Service
@Transactional
@RequiredArgsConstructor
public class MatchedItemSaveService {
    private final MatchedItemRepository matchedItemRepository;
    private final FoundItemRepository foundItemRepository;
    private final LostItemRepository lostItemRepository;
    private final ApplicationEventPublisher eventPublisher;

    @Transactional
    public void saveMatchingResults2(Integer foundItemId, MatchedItemResponse response) {
        if (foundItemId == null || response == null || response.getResult() == null) {
            return;
        }

        // 습득물 엔티티 조회
        FoundItem foundItem = foundItemRepository.findById(foundItemId)
                .orElseThrow(() -> new CustomException(ErrorCode.ITEM_NOT_FOUND));

        // 유사도 높은 순으로 정렬한 후 상위 5개만 선택
        List<MatchedItemResponse.MatchItem> matches = response.getResult().getMatches().stream()
                .sorted(Comparator.comparing(MatchedItemResponse.MatchItem::getSimilarity).reversed())
                .limit(5)
                .toList();

        LocalDateTime now = LocalDateTime.now();

        // 매칭할 모든 분실물 ID 목록 생성
        List<Integer> lostItemIds = matches.stream()
                .map(match -> match.getItem().getId())
                .collect(Collectors.toList());

        // 한 번의 쿼리로 모든 분실물 데이터 조회
        Map<Integer, LostItem> lostItemMap = lostItemRepository.findAllById(lostItemIds).stream()
                .collect(Collectors.toMap(LostItem::getId, item -> item));

        List<MatchedItem> matchedItemsToSave = new ArrayList<>();

        for (MatchedItemResponse.MatchItem match : matches) {
            Integer lostItemId = match.getItem().getId();
            LostItem lostItem = lostItemMap.get(lostItemId);

            // 분실물이 존재하고 이미 매칭 정보가 없는 경우에만 처리
            if (lostItem != null && !matchedItemRepository.existsByLostItemAndFoundItem(lostItem, foundItem)) {
                // 유사도 소수점에서 정수로 변환
                int similarityScore = Math.round(match.getSimilarity() * 100);

                MatchedItem matchedItem = MatchedItem.builder()
                        .lostItem(lostItem)
                        .foundItem(foundItem)
                        .score(similarityScore)
                        .matchedAt(now)
                        .build();

                // 리스트에 추가 (바로 저장하지 않음)
                matchedItemsToSave.add(matchedItem);
                log.info("매칭 항목 준비: foundItemId={}, lostItemId={}, score={}",
                        matchedItem.getFoundItem(), matchedItem.getLostItem(), matchedItem.getScore());
            }
        }

        // 한 번에 모든 항목 저장
        if (!matchedItemsToSave.isEmpty()) {
            matchedItemRepository.saveAll(matchedItemsToSave);
            for (MatchedItemResponse.MatchItem match : matches) {
                log.info("match item : {}", match.getItem().toString());
            }

            for (MatchedItem item : matchedItemsToSave) {
                log.info("FoundItem: {}", item.getFoundItem());
                log.info("LostItem: {}", item.getLostItem());
            }

            log.info("한 번에 총 {}개의 매칭 항목 저장 완료", matchedItemsToSave.size());
        }

        matchedItemRepository.flush();

        eventPublisher.publishEvent(new MatchedItemEvent(this, matchedItemsToSave));
    }


}
