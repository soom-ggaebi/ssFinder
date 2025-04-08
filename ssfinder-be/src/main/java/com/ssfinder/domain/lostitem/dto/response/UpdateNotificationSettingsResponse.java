package com.ssfinder.domain.lostitem.dto.response;

import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.annotation.JsonNaming;
import lombok.Getter;
import lombok.Setter;

@JsonNaming(PropertyNamingStrategies.SnakeCaseStrategy.class)
@Getter
@Setter
public class UpdateNotificationSettingsResponse {

    private Integer id;

    private Boolean notificationEnabled;
}
