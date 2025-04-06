package com.ssfinder.domain.founditem.repository;

import com.ssfinder.domain.founditem.entity.FoundItemDocument;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.elasticsearch.repository.ElasticsearchRepository;
import org.springframework.stereotype.Repository;

/**
 * packageName    : com.ssfinder.domain.found.repository<br>
 * fileName       : FoundItemDocumentRepository.java<br>
 * author         : joker901010<br>
 * date           : 2025-04-04<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-04          joker901010           최초생성<br>
 * <br>
 */
@Repository
public interface FoundItemDocumentRepository extends ElasticsearchRepository<FoundItemDocument, String> {
}
