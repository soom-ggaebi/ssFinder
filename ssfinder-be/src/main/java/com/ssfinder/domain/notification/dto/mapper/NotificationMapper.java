package com.ssfinder.domain.notification.dto.mapper;

import com.ssfinder.domain.notification.dto.response.NotificationHistoryResponse;
import com.ssfinder.domain.notification.dto.response.NotificationSliceResponse;
import com.ssfinder.domain.notification.entity.NotificationHistory;
import org.mapstruct.Mapper;
import org.mapstruct.ReportingPolicy;
import org.springframework.data.domain.Slice;

import java.util.List;
import java.util.Objects;

/**
 * packageName    : com.ssfinder.domain.notification.dto.mapper<br>
 * fileName       : NotificationMapper.java<br>
 * author         : okeio<br>
 * date           : 2025-04-02<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-02          okeio           최초생성<br>
 * <br>
 */
@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.WARN)
public interface NotificationMapper {

    default NotificationSliceResponse toNotificationSliceResponse(Slice<NotificationHistory> slice) {
        if (Objects.isNull(slice)) {
            return null;
        }

        List<NotificationHistoryResponse> content = slice.getContent().stream()
                .map(this::toNotificationHistoryResponse)
                .toList();

        return NotificationSliceResponse.builder()
                .content(content)
                .hasNext(slice.hasNext())
                .build();
    }

    NotificationHistoryResponse toNotificationHistoryResponse(NotificationHistory history);
}
