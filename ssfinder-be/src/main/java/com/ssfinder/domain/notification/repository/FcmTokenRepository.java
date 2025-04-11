package com.ssfinder.domain.notification.repository;

import com.ssfinder.domain.notification.entity.FcmToken;
import com.ssfinder.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.notification.repository<br>
 * fileName       : FcmTokenRepository.java<br>
 * author         : okeio<br>
 * date           : 2025-03-24<br>
 * description    : FcmToken entity의 레포지토리 클래스입니다. <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio           최초생성<br>
 * 2025-04-04          okeio           토큰 조회 메서드 추가<br>
 * <br>
 */
@Repository
public interface FcmTokenRepository extends JpaRepository<FcmToken, Integer> {
    Optional<FcmToken> findByUserAndToken(User user, String token);
    List<FcmToken> findByToken(String token);
    List<FcmToken> findAllByUser(User user);
}
