package com.ssfinder.domain.founditem.repository;

import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FoundItemDocumentRepository extends ElasticsearchRepository<FoundItemDocument, String> {
    Page<FoundItemDocument> findByUserId(String userId, Pageable pageable);
}
