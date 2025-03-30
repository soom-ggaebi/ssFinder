package com.ssfinder.domain.founditem.service;

import com.ssfinder.domain.founditem.dto.mapper.FoundItemDocumentMapper;
import com.ssfinder.domain.founditem.entity.FoundItem;
import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import com.ssfinder.domain.founditem.repository.FoundItemDocumentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class ElasticsearchService {

    private final FoundItemDocumentRepository foundItemDocumentRepository;
    private final FoundItemDocumentMapper foundItemDocumentMapper;

    @Async("elasticsearchTaskExecutor")
    public void indexFoundItem(FoundItem foundItem, String hdfsImagePath) {
        try {
            FoundItemDocument document = foundItemDocumentMapper.toDocument(foundItem, hdfsImagePath);
            foundItemDocumentRepository.save(document);
        } catch (Exception e) {
            System.out.println(e);
        }
    }

    @Async("elasticsearchTaskExecutor")
    public void updateFoundItem(FoundItem foundItem, String hdfsImagePath) {
        try {
            FoundItemDocument document = foundItemDocumentMapper.toDocument(foundItem, hdfsImagePath);
            foundItemDocumentRepository.save(document);
        } catch (Exception e) {
            System.out.println(e);
        }
    }

    @Async("elasticsearchTaskExecutor")
    public void deleteFoundItem(Integer itemId) {
        try {
            foundItemDocumentRepository.deleteById(itemId.toString());
        } catch (Exception e) {
            System.out.println(e);
        }
    }
}
