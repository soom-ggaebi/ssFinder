package com.ssfinder.global.common.pagination;

import lombok.RequiredArgsConstructor;

import java.util.List;

@RequiredArgsConstructor
public class CursorScrollResponse<T> {
    private final List<T> itemWithNextCursor;
    private final int countPerScroll;

    public static <T> CursorScrollResponse<T> of(List<T> itemWithNextCursor, int size) {
        return new CursorScrollResponse<>(itemWithNextCursor, size);
    }

    public boolean isLastScroll() {
        return this.itemWithNextCursor.size() <= countPerScroll;
    }

    public List<T> getCurrentScrollItems() {
        if(isLastScroll()) {
            return this.itemWithNextCursor;
        }

        return this.itemWithNextCursor.subList(0, countPerScroll);
    }

    public T getNextCursor() {
        return itemWithNextCursor.get(countPerScroll);
    }
}
