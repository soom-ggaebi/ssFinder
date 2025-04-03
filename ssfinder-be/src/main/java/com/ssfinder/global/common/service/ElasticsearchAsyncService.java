package com.ssfinder.global.common.service;

import com.ssfinder.domain.founditem.dto.mapper.FoundItemMapper;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import com.ssfinder.domain.founditem.repository.FoundItemDocumentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.mapping.IndexCoordinates;
import org.springframework.data.elasticsearch.core.query.IndexQuery;
import org.springframework.data.elasticsearch.core.query.IndexQueryBuilder;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class ElasticsearchAsyncService {

    private final FoundItemDocumentRepository foundItemDocumentRepository;
    private final FoundItemMapper foundItemMapper;
    private final ElasticsearchRetryQueue retryQueue;
    private final ElasticsearchOperations elasticsearchOperations;

    // 재시도 관련 설정
    private static final int MAX_RETRY_ATTEMPTS = 3;
    private static final long[] RETRY_DELAYS = {1, 5, 15}; // 초 단위로 점진적 증가
    private static final String INDEX_NAME = "found-items";

    /**
     * 비동기로 Elasticsearch에 FoundItem 정보를 저장합니다.
     *
     * @param foundItem MySQL에 저장된 FoundItem 엔티티
     */
    @Async("elasticsearchExecutor")
    public void saveFoundItemToElasticsearch(FoundItem foundItem) {
        saveFoundItemToElasticsearchWithRetry(foundItem, 0);
    }

    /**
     * 비동기로 Elasticsearch에서 FoundItem 문서를 삭제합니다.
     *
     * @param documentId 삭제할 문서 ID (MySQL ID와 동일)
     */
    @Async("elasticsearchExecutor")
    public void deleteFoundItemFromElasticsearch(String documentId) {
        deleteFoundItemFromElasticsearchWithRetry(documentId, 0);
    }

    /**
     * 재시도 로직이 포함된 Elasticsearch 저장 메서드
     * MySQL ID를 Elasticsearch _id로 사용합니다.
     *
     * @param foundItem MySQL에 저장된 FoundItem 엔티티
     * @param retryCount 현재 재시도 횟수
     */
    private void saveFoundItemToElasticsearchWithRetry(FoundItem foundItem, int retryCount) {
        try {
            log.info("Elasticsearch에 Found Item 저장 시작(시도 {}): MySQL ID={}",
                    retryCount + 1, foundItem.getId());

            FoundItemDocument document = foundItemMapper.entityToDocument(foundItem);

            String documentId = String.valueOf(foundItem.getId());

            IndexQuery indexQuery = new IndexQueryBuilder()
                    .withId(documentId)
                    .withObject(document)
                    .build();

            elasticsearchOperations.index(indexQuery, IndexCoordinates.of(INDEX_NAME));

            log.info("Elasticsearch에 Found Item 저장 완료: MySQL ID={}, ES ID={}",
                    foundItem.getId(), documentId);

        } catch (Exception e) {
            handleSaveFailure(foundItem, retryCount, e);
        }
    }

    /**
     * 재시도 로직이 포함된 Elasticsearch 삭제 메서드
     *
     * @param documentId 삭제할 문서 ID
     * @param retryCount 현재 재시도 횟수
     */
    private void deleteFoundItemFromElasticsearchWithRetry(String documentId, int retryCount) {
        try {
            log.info("Elasticsearch에서 문서 삭제 시작(시도 {}): ID={}",
                    retryCount + 1, documentId);

            elasticsearchOperations.delete(documentId, IndexCoordinates.of(INDEX_NAME));

            log.info("Elasticsearch에서 문서 삭제 완료: ID={}", documentId);

        } catch (Exception e) {
            handleDeleteFailure(documentId, retryCount, e);
        }
    }

    // 저장 실패 처리 로직
    private void handleSaveFailure(FoundItem foundItem, int retryCount, Exception e) {
        log.error("Elasticsearch에 Found Item 저장 실패(시도 {}): MySQL ID={}, 오류={}",
                retryCount + 1, foundItem.getId(), e.getMessage());

        if (retryCount < MAX_RETRY_ATTEMPTS - 1) {
            scheduleRetry(foundItem, retryCount);
        } else {
            log.error("Elasticsearch 저장 최대 재시도 횟수 초과. MySQL ID={}", foundItem.getId());
            addToRecoveryQueue(foundItem);
        }
    }

    // 삭제 실패 처리 로직
    private void handleDeleteFailure(String documentId, int retryCount, Exception e) {
        log.error("Elasticsearch에서 문서 삭제 실패(시도 {}): ID={}, 오류={}",
                retryCount + 1, documentId, e.getMessage());

        if (retryCount < MAX_RETRY_ATTEMPTS - 1) {
            scheduleDeleteRetry(documentId, retryCount);
        } else {
            log.error("Elasticsearch 삭제 최대 재시도 횟수 초과. ID={}", documentId);
            // 삭제 실패 알림 또는 추가 복구 로직
        }
    }

    // 지수 백오프 방식으로 재시도를 스케줄링
    private void scheduleRetry(FoundItem foundItem, int retryCount) {
        int nextRetryCount = retryCount + 1;
        long delaySeconds = RETRY_DELAYS[retryCount];

        log.info("Elasticsearch 저장 재시도 예약: MySQL ID={}, {} 초 후 재시도",
                foundItem.getId(), delaySeconds);

        CompletableFuture.delayedExecutor(delaySeconds, TimeUnit.SECONDS)
                .execute(() -> saveFoundItemToElasticsearchWithRetry(foundItem, nextRetryCount));
    }

    // 지수 백오프 방식으로 삭제 재시도를 스케줄링
    private void scheduleDeleteRetry(String documentId, int retryCount) {
        int nextRetryCount = retryCount + 1;
        long delaySeconds = RETRY_DELAYS[retryCount];

        log.info("Elasticsearch 삭제 재시도 예약: ID={}, {} 초 후 재시도",
                documentId, delaySeconds);

        CompletableFuture.delayedExecutor(delaySeconds, TimeUnit.SECONDS)
                .execute(() -> deleteFoundItemFromElasticsearchWithRetry(documentId, nextRetryCount));
    }

    // 최종 실패 시 복구 큐에 추가
    private void addToRecoveryQueue(FoundItem foundItem) {
        try {
            retryQueue.addFailedItem(foundItem);
            log.info("Failed item added to recovery queue: MySQL ID={}", foundItem.getId());
        } catch (Exception e) {
            log.error("Failed to add item to recovery queue: MySQL ID={}, Error={}",
                    foundItem.getId(), e.getMessage(), e);
        }
    }

}