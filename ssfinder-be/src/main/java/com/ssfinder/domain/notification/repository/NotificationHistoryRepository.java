package com.ssfinder.domain.notification.repository;

import com.ssfinder.domain.notification.entity.NotificationHistory;
import com.ssfinder.domain.notification.entity.NotificationType;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Slice;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

/**
 * packageName    : com.ssfinder.domain.notification.repository<br>
 * fileName       : NotificationHistoryRepository.java<br>
 * author         : okeio<br>
 * date           : 2025-04-02<br>
 * description    : 알림 내역(NotificationHistory) 엔티티에 대한 데이터 접근을 처리하는 JPA 리포지토리입니다.<br>
 *                  사용자별, 알림 유형별, 페이징 조건에 따라 다양한 조회 기능을 제공합니다.<br>
 * ===========================================================<br>
 * DATE              AUTHOR             NOTE<br>
 * -----------------------------------------------------------<br>
 * 2025-04-02          okeio           최초생성<br>
 * 2025-04-03          okeio           타입 필터링 없는 알림 이력 조회 메서드 추가<br>
 * <br>
 */
public interface NotificationHistoryRepository extends JpaRepository<NotificationHistory, Integer> {

    /**
     * 삭제되지 않은 사용자의 모든 알림 내역을 최신순으로 페이징하여 조회합니다.
     *
     * <p>
     * 알림 유형 필터 없이, 단순히 사용자별로 전체 알림 내역을 최신순으로 제공합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param pageable 페이징 정보
     * @return 알림 내역 슬라이스
     */
    Slice<NotificationHistory> findByUserIdAndIsDeletedFalseOrderBySendAtDesc(Integer userId, Pageable pageable);

    /**
     * 특정 알림 ID 이전의 알림들 중, 삭제되지 않은 사용자의 알림 내역을 최신순으로 페이징 조회합니다.
     *
     * <p>
     * 무한 스크롤 방식 구현 시 사용되며, 마지막 ID 기준으로 이후 데이터를 조회합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param id 마지막 알림 ID (기준점)
     * @param pageable 페이징 정보
     * @return 알림 내역 슬라이스
     */
    Slice<NotificationHistory> findByUserIdAndIdLessThanAndIsDeletedFalseOrderBySendAtDesc(Integer userId, Integer id, Pageable pageable);

    /**
     * 특정 알림 유형에 해당하며 삭제되지 않은 사용자 알림 내역을 최신순으로 페이징 조회합니다.
     *
     * <p>
     * 알림 타입별 목록을 제공하며, 무한 스크롤이 아닌 일반적인 페이징에 적합합니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param type 알림 유형
     * @param pageable 페이징 정보
     * @return 알림 내역 슬라이스
     */
    Slice<NotificationHistory> findByUserIdAndTypeAndIsDeletedFalseOrderBySendAtDesc(Integer userId, NotificationType type, Pageable pageable);

    /**
     * 특정 알림 ID 이전 중, 알림 유형까지 포함하여 삭제되지 않은 사용자 알림 내역을 최신순으로 페이징 조회합니다.
     *
     * <p>
     * 알림 유형과 ID 기준의 무한 스크롤 구현 시 사용됩니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param type 알림 유형
     * @param id 마지막 알림 ID (기준점)
     * @param pageable 페이징 정보
     * @return 알림 내역 슬라이스
     */
    Slice<NotificationHistory> findByUserIdAndTypeAndIdLessThanAndIsDeletedFalseOrderBySendAtDesc(Integer userId, NotificationType type, Integer id, Pageable pageable);

    /**
     * 특정 사용자와 알림 ID에 해당하는 알림 내역을 조회합니다.
     *
     * <p>
     * 사용자 인증을 기반으로 알림을 직접 삭제하거나 상세 조회할 때 사용됩니다.
     * </p>
     *
     * @param id 알림 ID
     * @param userId 사용자 ID
     * @return 알림 내역 Optional
     */
    Optional<NotificationHistory> findByIdAndUserId(Integer id, Integer userId);

    /**
     * 특정 사용자 및 알림 유형에 해당하는 삭제되지 않은 알림 내역 전체를 조회합니다.
     *
     * <p>
     * 알림 유형별 일괄 삭제 등의 기능에 사용됩니다.
     * </p>
     *
     * @param userId 사용자 ID
     * @param type 알림 유형
     * @return 알림 내역 리스트
     */
    List<NotificationHistory> findByUserIdAndTypeAndIsDeletedFalse(Integer userId, NotificationType type);
}
