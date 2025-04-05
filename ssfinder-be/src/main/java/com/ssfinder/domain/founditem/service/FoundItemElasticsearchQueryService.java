package com.ssfinder.domain.founditem.service;

import com.ssfinder.domain.founditem.dto.converter.FoundItemDtoConverter;
import com.ssfinder.domain.founditem.dto.request.FoundItemFilterRequest;
import com.ssfinder.domain.founditem.dto.request.FoundItemViewportRequest;
import com.ssfinder.domain.founditem.dto.response.FoundItemClusterResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemDetailResponse;
import com.ssfinder.domain.founditem.dto.response.FoundItemSummaryResponse;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import com.ssfinder.domain.founditem.query.FoundItemQueryBuilder;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.*;
import org.springframework.data.elasticsearch.core.ElasticsearchOperations;
import org.springframework.data.elasticsearch.core.SearchHit;
import org.springframework.data.elasticsearch.core.SearchHits;
import org.springframework.data.elasticsearch.core.query.FetchSourceFilter;
import org.springframework.data.elasticsearch.core.query.StringQuery;
import org.springframework.data.elasticsearch.core.query.Criteria;
import org.springframework.data.elasticsearch.core.query.CriteriaQuery;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class FoundItemElasticsearchQueryService {

    private final ElasticsearchOperations elasticsearchOperations;

    @Transactional(readOnly = true)
    public Page<FoundItemDetailResponse> getMyFoundItems(int userId, Pageable pageable) {
        String userIdStr = String.valueOf(userId);
        try {
            Criteria criteria = new Criteria("user_id").exists().is(userIdStr);
            CriteriaQuery query = new CriteriaQuery(criteria).setPageable(pageable);
            SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);
            List<FoundItemDetailResponse> content = searchHits.getSearchHits().stream()
                    .map(SearchHit::getContent)
                    .map(FoundItemDtoConverter::convertToDetailResponse)
                    .collect(Collectors.toList());
            return new PageImpl<>(content, pageable, searchHits.getTotalHits());
        } catch (Exception e) {
            log.error("Elasticsearch 검색 중 오류 발생: {}", e.getMessage());
            return new PageImpl<>(Collections.emptyList(), pageable, 0);
        }
    }

    @Transactional(readOnly = true)
    public Page<FoundItemSummaryResponse> getPagedFoundItemsInViewport(Integer userId, FoundItemViewportRequest request, Pageable pageable) {
        String queryJson = FoundItemQueryBuilder.buildViewportQuery(request);
        StringQuery query = new StringQuery(queryJson);
        query.setPageable(pageable);
        query.addSourceFilter(FetchSourceFilter.of(
                new String[]{"mysql_id", "image", "category_major", "category_minor", "name", "location", "stored_at", "created_at", "management_id"},
                null));
        SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);
        List<FoundItemSummaryResponse> content = searchHits.getSearchHits().stream()
                .map(hit -> FoundItemDtoConverter.convertToSummaryResponse(hit.getContent()))
                .collect(Collectors.toList());
        return new PageImpl<>(content, pageable, searchHits.getTotalHits());
    }

    @Transactional(readOnly = true)
    public Page<FoundItemSummaryResponse> getFilteredFoundItemsForDetail(Integer userId, FoundItemFilterRequest request, Pageable pageable) {
        String queryJson = FoundItemQueryBuilder.buildFilterQuery(request);
        StringQuery query = new StringQuery(queryJson);
        query.setPageable(pageable);
        query.addSourceFilter(FetchSourceFilter.of(
                new String[]{"mysql_id", "image", "category_major", "category_minor", "name", "location", "stored_at", "created_at", "management_id"},
                null));
        SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);
        List<FoundItemSummaryResponse> content = searchHits.getSearchHits().stream()
                .map(hit -> FoundItemDtoConverter.convertToSummaryResponse(hit.getContent()))
                .collect(Collectors.toList());
        return new PageImpl<>(content, pageable, searchHits.getTotalHits());
    }

    @Async("elasticsearchExecutor")
    @Transactional(readOnly = true)
    public CompletableFuture<List<FoundItemClusterResponse>> getCoordinatesInViewportForClusteringAsync(FoundItemViewportRequest request) {
        List<FoundItemClusterResponse> allResponses = new ArrayList<>();
        int batchSize = 10000;
        int batchCount = 0;
        List<Object> searchAfterValues = null;
        boolean hasMoreData = true;
        while (hasMoreData) {
            String queryJson = FoundItemQueryBuilder.buildViewportQuery(request);
            StringQuery query = new StringQuery(queryJson);
            query.setPageable(PageRequest.of(0, batchSize, Sort.by(Sort.Direction.ASC, "mysql_id")));
            query.addSourceFilter(FetchSourceFilter.of(new String[]{"mysql_id", "latitude", "longitude"}, null));
            if (searchAfterValues != null) {
                query.setSearchAfter(searchAfterValues);
            }
            SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);
            if (!searchHits.hasSearchHits()) {
                hasMoreData = false;
                break;
            }
            for (SearchHit<FoundItemDocument> hit : searchHits.getSearchHits()) {
                FoundItemDocument doc = hit.getContent();
                FoundItemClusterResponse response = new FoundItemClusterResponse();
                response.setId(Integer.valueOf(doc.getMysqlId()));
                response.setLatitude(doc.getLatitude());
                response.setLongitude(doc.getLongitude());
                allResponses.add(response);
            }
            batchCount++;
            if (!searchHits.getSearchHits().isEmpty()) {
                searchAfterValues = searchHits.getSearchHits().get(searchHits.getSearchHits().size() - 1).getSortValues();
            }
            if (searchHits.getSearchHits().size() < batchSize || batchCount >= 100) {
                hasMoreData = false;
            }
        }
        return CompletableFuture.completedFuture(allResponses);
    }

    @Async("elasticsearchExecutor")
    @Transactional(readOnly = true)
    public CompletableFuture<List<FoundItemClusterResponse>> getFilteredFoundItemsAsync(FoundItemFilterRequest request) {
        List<FoundItemClusterResponse> allResponses = new ArrayList<>();
        int batchSize = 10000;
        int batchCount = 0;
        List<Object> searchAfterValues = null;
        boolean hasMoreData = true;
        String queryJson = FoundItemQueryBuilder.buildFilterQuery(request);
        while (hasMoreData) {
            StringQuery query = new StringQuery(queryJson);
            query.setPageable(PageRequest.of(0, batchSize, Sort.by(Sort.Direction.ASC, "mysql_id")));
            query.addSourceFilter(FetchSourceFilter.of(new String[]{"mysql_id", "latitude", "longitude"}, null));
            if (searchAfterValues != null) {
                query.setSearchAfter(searchAfterValues);
            }
            SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);
            if (!searchHits.hasSearchHits()) {
                hasMoreData = false;
                break;
            }
            for (SearchHit<FoundItemDocument> hit : searchHits.getSearchHits()) {
                FoundItemDocument doc = hit.getContent();
                FoundItemClusterResponse response = new FoundItemClusterResponse();
                response.setId(Integer.valueOf(doc.getMysqlId()));
                response.setLatitude(doc.getLatitude());
                response.setLongitude(doc.getLongitude());
                allResponses.add(response);
            }
            batchCount++;
            if (!searchHits.getSearchHits().isEmpty()) {
                searchAfterValues = searchHits.getSearchHits().get(searchHits.getSearchHits().size() - 1).getSortValues();
            }
            if (searchHits.getSearchHits().size() < batchSize || batchCount >= 100) {
                hasMoreData = false;
            }
        }
        return CompletableFuture.completedFuture(allResponses);
    }

    @Transactional(readOnly = true)
    public Page<FoundItemSummaryResponse> getClusterDetailItems(Integer userId, List<Integer> ids, Pageable pageable) {
        int totalSize = ids.size();
        int pageSize = pageable.getPageSize();
        int pageNumber = pageable.getPageNumber();
        int startIndex = pageNumber * pageSize;
        int endIndex = Math.min(startIndex + pageSize, totalSize);
        if (startIndex >= totalSize) {
            return new PageImpl<>(Collections.emptyList(), pageable, totalSize);
        }
        List<Integer> pageIds = ids.subList(startIndex, endIndex);
        List<String> idStrings = pageIds.stream().map(String::valueOf).collect(Collectors.toList());
        Criteria criteria = new Criteria("mysql_id").in(idStrings);
        CriteriaQuery query = new CriteriaQuery(criteria);
        if (pageable.getSort().isSorted()) {
            query.addSort(pageable.getSort());
        }
        query.setPageable(PageRequest.of(0, pageSize));
        SearchHits<FoundItemDocument> searchHits = elasticsearchOperations.search(query, FoundItemDocument.class);
        Map<String, FoundItemDocument> docMap = new HashMap<>();
        for (SearchHit<FoundItemDocument> hit : searchHits.getSearchHits()) {
            FoundItemDocument doc = hit.getContent();
            if (doc.getMysqlId() != null) {
                docMap.put(doc.getMysqlId(), doc);
            }
        }
        List<FoundItemSummaryResponse> content = new ArrayList<>();
        for (String idString : idStrings) {
            FoundItemDocument doc = docMap.get(idString);
            if (doc != null) {
                FoundItemSummaryResponse response = FoundItemDtoConverter.convertToSummaryResponse(doc);
                content.add(response);
            }
        }
        return new PageImpl<>(content, pageable, totalSize);
    }
}