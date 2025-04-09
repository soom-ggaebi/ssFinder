package com.ssfinder.domain.matchedItem.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ssfinder.domain.matchedItem.dto.request.MatchedItemRequest;
import com.ssfinder.domain.matchedItem.dto.response.MatchedItemResponse;
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

        // 유사도 70% 이상인 항목만 필터링
        List<MatchedItemResponse.MatchItem> matches = response.getResult().getMatches().stream()
                .filter(match -> match.getSimilarity() >= 0.7)
                .collect(Collectors.toList());

        LocalDateTime now = LocalDateTime.now();

        List<MatchedItem> matchedItemsToSave = new ArrayList<>();

        for (MatchedItemResponse.MatchItem match : matches) {
            Integer foundItemId = match.getItem().getId();

            // 습득물 엔티티 조회
            FoundItem foundItem = foundItemRepository.findById(foundItemId)
                    .orElseThrow(() -> new CustomException(ErrorCode.ITEM_NOT_FOUND));

            // 이미 매칭 정보가 있는지 확인
            if (!matchedItemRepository.existsByLostItemAndFoundItem(lostItem, foundItem)) {
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

    public MatchedItemResponse getMatchedItems(Integer lostItemId) {
        // 분실물 엔티티 조회
        LostItem lostItem = lostItemRepository.findById(lostItemId)
                .orElseThrow(() -> new CustomException(ErrorCode.ITEM_NOT_FOUND));

        List<MatchedItem> matchedItems = matchedItemRepository.findByLostItemOrderByScoreDesc(lostItem);

        if (matchedItems.isEmpty()) {
            return MatchedItemResponse.builder()
                    .success(true)
                    .message("매칭된 습득물이 없습니다.")
                    .build();
        }

        List<Integer> foundItemIds = matchedItems.stream()
                .map(matchedItem -> matchedItem.getFoundItem().getId())
                .collect(Collectors.toList());

        // 습득물 ID 목록으로 한번에 모든 습득물 조회
        List<FoundItem> foundItems = foundItemRepository.findAllById(foundItemIds);

        // 습득물을 Map으로 변환 (ID -> FoundItem)
        Map<Integer, FoundItem> foundItemMap = foundItems.stream()
                .collect(Collectors.toMap(FoundItem::getId, foundItem -> foundItem));

        List<MatchedItemResponse.MatchItem> matchItems = new ArrayList<>();

        for (MatchedItem matchedItem : matchedItems) {
            FoundItem foundItem = foundItemMap.get(matchedItem.getFoundItem().getId());

            // 습득물이 없으면 다음 항목으로 넘어감
            if (foundItem == null) continue;

            // 매치 아이템 생성
            MatchedItemResponse.MatchItem matchItem = MatchedItemResponse.MatchItem.builder()
                    .lostItemId(matchedItem.getLostItem().getId())
                    .foundItemId(matchedItem.getFoundItem().getId())
                    .similarity(matchedItem.getScore() / 100f)
                    .build();

            matchItems.add(matchItem);
        }

        MatchedItemResponse.MatchingResult result = MatchedItemResponse.MatchingResult.builder()
                .totalMatches(matchItems.size())
                .similarityThreshold(0.7f)
                .matches(matchItems)
                .build();

        return MatchedItemResponse.builder()
                .success(true)
                .message(String.format("%d개의 매칭된 습득물을 찾았습니다.", matchItems.size()))
                .result(result)
                .build();
    }
}