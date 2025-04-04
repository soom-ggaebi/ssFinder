package com.ssfinder.domain.founditem.dto.response;

import java.util.List;

/**
 * packageName    : com.ssfinder.domain.found.dto.response<br>
 * fileName       : SearchAfterPageResponse.java<br>
 * author         : leeyj<br>
 * date           : 2025-04-04<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-04          leeyj           최초생성<br>
 * <br>
 */
public class SearchAfterPageResponse<T> {
    private List<T> results;
    private Object[] nextSearchAfter;

    public SearchAfterPageResponse(List<T> results, Object[] nextSearchAfter) {
        this.results = results;
        this.nextSearchAfter = nextSearchAfter;
    }

    public List<T> getResults() {
        return results;
    }

    public Object[] getNextSearchAfter() {
        return nextSearchAfter;
    }
}