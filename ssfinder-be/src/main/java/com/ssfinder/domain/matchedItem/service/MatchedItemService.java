package com.ssfinder.domain.matchedItem.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssfinder.domain.itemcategory.dto.MatchedItemsTopFiveProjection;
import com.ssfinder.domain.matchedItem.dto.request.MatchedItemRequest;
import com.ssfinder.domain.matchedItem.dto.response.MatchedItemResponse;
import com.ssfinder.domain.matchedItem.dto.response.MatchedItemsTopFiveResponse;
import com.ssfinder.domain.matchedItem.entity.MatchedItem;
import com.ssfinder.domain.matchedItem.repository.MatchedItemRepository;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.repository.FoundItemRepository;
import com.ssfinder.domain.lostitem.entity.LostItem;
import com.ssfinder.domain.lostitem.repository.LostItemRepository;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * packageName    : com.ssfinder.domain.matchedItem.service<br>
 * fileName       : MatchedItemService.java<br>
 * author         : sonseohy<br>
 * date           : 2025-04-09<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-09          sonseohy           최초생성<br>
 * <br>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class MatchedItemService {
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private final FoundItemRepository foundItemRepository;
    private final MatchedItemRepository matchedItemRepository;
    private final LostItemRepository lostItemRepository;

    @Value("${matching.huggingface.url}")
    private String matchinghuggingFaceUrl;

    @Transactional
    public MatchedItemResponse findSimilarItems(MatchedItemRequest request) {
        log.info("AI 매칭 요청: {}", request);

        try {
            // HTTP 요청 헤더 설정
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            // 요청 데이터를 Map으로 변환
            Map<String, Object> requestMap = new HashMap<>();
            requestMap.put("category", request.getItemCategoryId());
            requestMap.put("name", request.getTitle());
            requestMap.put("color", request.getColor());
            requestMap.put("content", request.getDetail());
            requestMap.put("location", request.getLocation());
            requestMap.put("image_url", request.getImage());

            // HTTP 요청 엔티티 생성
            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestMap, headers);

            log.debug("Hugging Face API 호출: {}", matchinghuggingFaceUrl);

            // Hugging Face API로 요청 전송 및 응답 수신
            ResponseEntity<MatchedItemResponse> response = restTemplate.exchange(
                    matchinghuggingFaceUrl + "?threshold=" + (request.getThreshold() != null ? request.getThreshold() : 0.7),
                    HttpMethod.POST,
                    entity,
                    MatchedItemResponse.class
            );

            MatchedItemResponse matchingResponse = response.getBody();

            // 매칭 결과 처리
            if (matchingResponse != null && matchingResponse.isSuccess() &&
                    matchingResponse.getResult() != null && request.getLostItemId() != null) {
                // 매칭 결과를 DB에 저장
                saveMatchingResults(request.getLostItemId(), matchingResponse);
            }

            return matchingResponse;

        } catch (Exception e) {
            log.error("Hugging Face API 요청 중 오류 발생: {}", e.getMessage(), e);
            throw new CustomException(ErrorCode.EXTERNAL_API_ERROR);
        }
    }

    private void saveMatchingResults(Integer lostItemId, MatchedItemResponse response) {
        if (lostItemId == null || response == null || response.getResult() == null) {
            return;
        }

        // 분실물 엔티티 조회
        LostItem lostItem = lostItemRepository.findById(lostItemId)
                .orElseThrow(() -> new CustomException(ErrorCode.ITEM_NOT_FOUND));

        // 유사도 70% 이상인 항목만 필터링하고, 유사도 높은 순으로 정렬한 후 상위 5개만 선택
        List<MatchedItemResponse.MatchItem> matches = response.getResult().getMatches().stream()
                .filter(match -> match.getSimilarity() >= 0.7)
                .sorted(Comparator.comparing(MatchedItemResponse.MatchItem::getSimilarity).reversed())
                .limit(5)
                .collect(Collectors.toList());

        LocalDateTime now = LocalDateTime.now();

        // 매칭할 모든 습득물 ID 목록 생성
        List<Integer> foundItemIds = matches.stream()
                .map(match -> match.getItem().getId())
                .collect(Collectors.toList());

        // 한 번의 쿼리로 모든 습득물 데이터 조회
        Map<Integer, FoundItem> foundItemMap = foundItemRepository.findAllById(foundItemIds).stream()
                .collect(Collectors.toMap(FoundItem::getId, item -> item));

        List<MatchedItem> matchedItemsToSave = new ArrayList<>();

        for (MatchedItemResponse.MatchItem match : matches) {
            Integer foundItemId = match.getItem().getId();
            FoundItem foundItem = foundItemMap.get(foundItemId);

            // 습득물이 존재하고 이미 매칭 정보가 없는 경우에만 처리
            if (foundItem != null && !matchedItemRepository.existsByLostItemAndFoundItem(lostItem, foundItem)) {
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
                log.info("매칭 항목 준비: lostItemId={}, foundItemId={}, score={}",
                        lostItemId, foundItemId, similarityScore);
            }
        }

        // 한 번에 모든 항목 저장
        if (!matchedItemsToSave.isEmpty()) {
            matchedItemRepository.saveAll(matchedItemsToSave);
            log.info("총 {}개의 매칭 항목 저장 완료", matchedItemsToSave.size());
        }
    }

    public List<MatchedItemsTopFiveResponse> getMatchedItems(Integer lostId) {
        return matchedItemRepository.findTop5MatchedItemsNative(lostId).stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    private MatchedItemsTopFiveResponse toDto(MatchedItemsTopFiveProjection p) {
        return MatchedItemsTopFiveResponse.builder()
                .id(p.getId())
                .image(p.getImage())
                .majorCategory(p.getMajorCategory())
                .minorCategory(p.getMinorCategory())
                .name(p.getName())
                .type(p.getType())
                .location(p.getLocation())
                .storedAt(p.getStoredAt())
                .status(p.getStatus())
                .createdAt(p.getCreatedAt())
                .score(p.getScore())
                .build();
    }
}