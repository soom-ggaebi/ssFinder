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
 * description    : FCM 토큰 엔티티에 대한 데이터 접근을 처리하는 JPA 리포지토리입니다.<br>
 *                  사용자 기반 또는 토큰 값 기반의 조회 기능을 제공합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-24          okeio           최초생성<br>
 * 2025-04-04          okeio           토큰 조회 메서드 추가<br>
 * <br>
 */
@Repository
public interface FcmTokenRepository extends JpaRepository<FcmToken, Integer> {
    /**
     * 특정 사용자와 FCM 토큰으로 토큰 정보를 조회합니다.
     *
     * <p>
     * 사용자의 ID와 일치하는 FCM 토큰이 존재하는 경우 이를 반환합니다.
     * 중복 등록 방지를 위해 등록 전 존재 여부 확인에 사용됩니다.
     * </p>
     *
     * @param user  조회할 사용자 엔티티
     * @param token 조회할 FCM 토큰 문자열
     * @return 일치하는 FCM 토큰 정보가 존재하면 Optional로 반환, 없으면 빈 Optional 반환
     */
    Optional<FcmToken> findByUserAndToken(User user, String token);

    /**
     * 토큰 값으로 FCM 토큰 정보를 조회합니다.
     *
     * <p>
     * 주로 Firebase 메시지 전송 중 유효하지 않은 토큰을 삭제할 때 사용됩니다.
     * </p>
     *
     * @param token 조회할 FCM 토큰 문자열
     * @return 일치하는 FCM 토큰 정보가 존재하면 List로 반환, 없으면 빈 Optional 반환
     */
    List<FcmToken> findByToken(String token);

    /**
     * 사용자 ID 기준으로 등록된 모든 FCM 토큰 목록을 조회합니다.
     *
     * <p>
     * 하나의 사용자가 여러 기기에서 로그인한 경우를 지원하며,
     * 다중 토큰을 통한 푸시 알림 전송 등에 활용됩니다.
     * </p>
     *
     * @param user 조회할 사용자 엔티티
     * @return 해당 사용자와 연관된 모든 FCM 토큰 리스트
     */

    List<FcmToken> findAllByUser(User user);
}
