package com.ssfinder.domain.itemcategory.controller;

import com.ssfinder.domain.itemcategory.dto.ItemCategoryInfo;
import com.ssfinder.domain.itemcategory.service.ItemCategoryService;
import com.ssfinder.global.common.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
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
