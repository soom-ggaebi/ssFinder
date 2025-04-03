package com.ssfinder.global.common.service;

import com.ssfinder.domain.founditem.dto.mapper.FoundItemMapper;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import com.ssfinder.domain.founditem.repository.FoundItemDocumentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.Queue;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.atomic.AtomicInteger;

@Slf4j
@Component
@RequiredArgsConstructor
public class ElasticsearchRetryQueue {

    private final FoundItemDocumentRepository foundItemDocumentRepository;
    private final FoundItemMapper foundItemMapper;

    private final Queue<FoundItem> retryQueue = new ConcurrentLinkedQueue<>();
    private final Map<Integer, AtomicInteger> retryCountMap = new ConcurrentHashMap<>();

    private static final int MAX_RECOVERY_ATTEMPTS = 5;
    private static final int MAX_BATCH_SIZE = 20;

    // 저장 실패한 항목을 복구 큐에 추가
    public void addFailedItem(FoundItem foundItem) {
        Integer itemId = foundItem.getId();
        retryQueue.add(foundItem);
        retryCountMap.putIfAbsent(itemId, new AtomicInteger(0));
        log.info("항목이 복구 큐에 추가됨: MySQL ID={}", itemId);
    }

    // 주기적으로 복구 큐의 항목을 재시도 (5분마다 실행)
    @Scheduled(fixedRate = 300000) // 5분마다
    public void processRetryQueue() {
        log.info("복구 큐 처리 시작, 현재 큐 크기: {}", retryQueue.size());

        int processedCount = 0;
        while (!retryQueue.isEmpty() && processedCount < MAX_BATCH_SIZE) {
            FoundItem foundItem = retryQueue.poll();
            if (foundItem == null) continue;

            processedCount++;
            processRetryItem(foundItem);
        }

        log.info("복구 큐 처리 완료, 처리된 항목: {}, 남은 항목: {}",
                processedCount, retryQueue.size());
    }

    // 단일 재시도 항목 처리
    private void processRetryItem(FoundItem foundItem) {
        Integer itemId = foundItem.getId();
        AtomicInteger retryCount = retryCountMap.get(itemId);

        if (retryCount == null) {
            log.error("재시도 카운트를 찾을 수 없음: MySQL ID={}", itemId);
            return;
        }

        int currentRetryCount = retryCount.incrementAndGet();

        try {
            log.info("복구 큐에서 항목 재시도: MySQL ID={}, 시도 횟수={}",
                    itemId, currentRetryCount);

            FoundItemDocument document = foundItemMapper.entityToDocument(foundItem);
            foundItemDocumentRepository.save(document);

            log.info("복구 큐에서 항목 저장 성공: MySQL ID={}", itemId);
            retryCountMap.remove(itemId);

        } catch (Exception e) {
            log.error("복구 큐에서 재시도 실패: MySQL ID={}, 시도 횟수={}, 오류={}",
                    itemId, currentRetryCount, e.getMessage());

            if (currentRetryCount < MAX_RECOVERY_ATTEMPTS) {
                // 계속 재시도를 위해 다시 큐에 추가
                retryQueue.add(foundItem);
            } else {
                log.error("최대 복구 시도 횟수 초과, 항목 폐기: MySQL ID={}", itemId);
                retryCountMap.remove(itemId);
                // 최종 실패 로깅/알림
                notifyPermanentFailure(foundItem);
            }
        }
    }

    // 영구적인 실패에 대한 알림
    private void notifyPermanentFailure(FoundItem foundItem) {
        log.error("CRITICAL: Elasticsearch 항목 저장 영구 실패. MySQL ID={}를 수동으로 복구해야 합니다.",
                foundItem.getId());
        // 여기에 영구 실패에 대한 알림 로직 구현 (이메일, 슬랙, 모니터링 시스템 등)
    }

    // 큐 상태에 대한 정보 반환 (모니터링 목적)
    public Map<String, Object> getQueueStatus() {
        Map<String, Object> status = new ConcurrentHashMap<>();
        status.put("queueSize", retryQueue.size());
        status.put("retryItemsCount", retryCountMap.size());
        return status;
    }
}