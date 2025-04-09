package com.ssfinder.domain.user.repository;

import com.ssfinder.domain.user.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.user.repository<br>
 * fileName       : UserRepository.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    : User 엔티티에 대한 데이터베이스 접근을 담당하는 JPA 리포지토리 인터페이스입니다.<br>
 *                  providerId 기반 사용자 조회 기능을 제공합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * <br>
 */
public interface UserRepository extends JpaRepository<User, Integer> {
    /**
     * OAuth providerId를 기반으로 사용자를 조회합니다.
     *
     * @param providerId 소셜 로그인 provider ID (예: Kakao, Apple 등)
     * @return 해당 providerId를 가진 사용자 정보 (Optional)
     */
    Optional<User> findByProviderId(String providerId);
}
