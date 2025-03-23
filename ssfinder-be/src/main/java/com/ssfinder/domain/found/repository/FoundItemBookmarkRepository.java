package com.ssfinder.domain.found.repository;

import com.ssfinder.domain.found.entity.FoundItemBookmark;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FoundItemBookmarkRepository extends JpaRepository<FoundItemBookmark, Integer> {

    List<FoundItemBookmark> findByUserId(Integer userId);

    Optional<FoundItemBookmark> findByUserIdAndFoundItemId(Integer userId, Integer foundItemId);
}
