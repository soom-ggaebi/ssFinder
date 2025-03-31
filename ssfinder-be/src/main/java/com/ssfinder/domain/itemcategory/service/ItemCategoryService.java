package com.ssfinder.domain.itemcategory.service;

import com.ssfinder.domain.itemcategory.dto.ItemCategoryInfo;
import com.ssfinder.domain.itemcategory.repository.ItemCategoryRepository;
import com.ssfinder.global.common.exception.CustomException;
import com.ssfinder.global.common.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

/**
 * packageName    : com.ssfinder.domain.itemcategory.service<br>
 * fileName       : ItemCategoryService.java<br>
 * author         : nature1216 <br>
 * date           : 2025-04-01<br>
 * description    : ItemCategory service 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-01         nature1216          최초생성<br>
 * <br>
 */
@Service
@RequiredArgsConstructor
public class ItemCategoryService {
    ItemCategoryRepository itemCategoryRepository;
    public ItemCategoryInfo findWithParentById(Integer id) {
        return itemCategoryRepository.findWithParentById(id)
                .orElseThrow(() -> new CustomException(ErrorCode.CATEGORY_NOT_FOUND));
    }

}
