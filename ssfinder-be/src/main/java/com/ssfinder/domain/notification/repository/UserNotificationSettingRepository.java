package com.ssfinder.domain.notification.repository;

import com.ssfinder.domain.notification.entity.UserNotificationSettings;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.notification.repository<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-25<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-25          okeio           최초생성<br>
 * <br>
 */
public interface UserNotificationSettingRepository extends JpaRepository<UserNotificationSettings, Integer> {
    Optional<UserNotificationSettings> findByUserId(Integer userId);
}
