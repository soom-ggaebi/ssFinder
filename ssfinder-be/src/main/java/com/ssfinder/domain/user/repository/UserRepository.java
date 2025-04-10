package com.ssfinder.domain.user.repository;

import com.ssfinder.domain.user.dto.response.MyItemCountResponse;
import com.ssfinder.domain.user.entity.User;
import jakarta.validation.constraints.NotBlank;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

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
    Optional<User> findByProviderId(String providerId);

    @Query(value = """
      SELECT
        (SELECT COUNT(*) FROM lost_item   WHERE user_id = :userId) AS lost_count,
        (SELECT COUNT(*) FROM found_item  WHERE user_id = :userId) AS found_count
      """, nativeQuery = true)
    MyItemCountResponse countItemsByUserId(@Param("userId") Integer userId);
}
