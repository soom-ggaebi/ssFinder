package com.ssfinder.domain.founditem.repository;

import com.ssfinder.domain.founditem.entity.FoundItemBookmark;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FoundItemBookmarkRepository extends JpaRepository<FoundItemBookmark, Integer> {

    List<FoundItemBookmark> findByUserId(Integer userId);

    Optional<FoundItemBookmark> findByUserIdAndFoundItemId(Integer userId, Integer foundItemId);
}
