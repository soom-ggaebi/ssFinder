package com.ssfinder.domain.itemcategory.controller;

import com.ssfinder.domain.founditem.dto.response.FoundItemDocumentDetailResponse;
import com.ssfinder.domain.itemcategory.dto.ItemCategoryInfo;
import com.ssfinder.domain.itemcategory.service.ItemCategoryService;
import com.ssfinder.domain.user.dto.CustomUserDetails;
import com.ssfinder.global.common.response.ApiResponse;
import jakarta.validation.constraints.Min;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/category")
@RequiredArgsConstructor
public class ItemCategoryController {

    private final ItemCategoryService itemCategoryService;

    @GetMapping
    public ApiResponse<List<ItemCategoryInfo>> getItemCategory() {

        List<ItemCategoryInfo> respone = itemCategoryService.getItemCategory();

        return ApiResponse.ok(respone);
    }
}
