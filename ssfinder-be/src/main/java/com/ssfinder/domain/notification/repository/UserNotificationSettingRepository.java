package com.ssfinder.domain.notification.repository;

import com.ssfinder.domain.notification.entity.UserNotificationSetting;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.notification.repository<br>
 * fileName       : UserNotificationSettingRepository.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    : 사용자 알림 설정(UserNotificationSetting) 엔티티에 대한 데이터 접근을 처리하는 JPA 리포지토리입니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * <br>
 */
public interface UserNotificationSettingRepository extends JpaRepository<UserNotificationSetting, Integer> {
    Optional<UserNotificationSetting> findByUserId(Integer userId);
}
