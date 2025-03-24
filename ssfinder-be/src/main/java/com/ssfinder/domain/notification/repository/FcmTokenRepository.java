package com.ssfinder.domain.notification.repository;

import com.ssfinder.domain.notification.entity.FcmToken;
import com.ssfinder.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.notification.repository<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-24<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio           최초생성<br>
 * <br>
 */
@Repository
public interface FcmTokenRepository extends JpaRepository<FcmToken, Integer> {
    Optional<FcmToken> findByUserAndFcmToken(User user, String fcmToken);
}
