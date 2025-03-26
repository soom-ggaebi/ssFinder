package com.ssfinder.domain.lostitem.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.*;

import java.time.LocalDateTime;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class LostItemStatusUpdateResponse {

    private Integer id;

    private String status;

    private LocalDateTime updatedAt;
}
