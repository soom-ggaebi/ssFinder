package com.ssfinder.domain.user.repository;

import com.ssfinder.domain.user.entity.User;
import jakarta.validation.constraints.NotBlank;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.user.repository<br>
 * fileName       : *.java<br>
 * author         : okeio<br>
 * date           : 2025-03-19<br>
 * description    :  <br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-03-19          okeio           최초생성<br>
 * <br>
 */
public interface UserRepository extends JpaRepository<User, Integer> {
    Optional<User> findByProviderId(@NotBlank String providerId);
}
