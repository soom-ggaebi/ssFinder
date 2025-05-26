import 'package:sumsumfinder/models/noti_model.dart';

class NotificationState {
  // 알림 유형별 데이터
  final Map<NotificationType, List<NotificationItem>> notificationsMap;
  // 로딩 상태
  final Map<NotificationType, bool> isLoadingMap;
  // 더 불러올 데이터 있는지 여부
  final Map<NotificationType, bool> hasMoreMap;
  // 페이지네이션을 위한 마지막 ID
  final Map<NotificationType, int?> lastIdMap;

  NotificationState({
    required this.notificationsMap,
    required this.isLoadingMap,
    required this.hasMoreMap,
    required this.lastIdMap,
  });

  // 초기 상태 생성
  factory NotificationState.initial() {
    return NotificationState(
      notificationsMap: {
        NotificationType.ALL: [],
        NotificationType.TRANSFER: [],
        NotificationType.CHAT: [],
        NotificationType.AI_MATCH: [],
        NotificationType.ITEM_REMINDER: [],
      },
      isLoadingMap: {
        NotificationType.ALL: false,
        NotificationType.TRANSFER: false,
        NotificationType.CHAT: false,
        NotificationType.AI_MATCH: false,
        NotificationType.ITEM_REMINDER: false,
      },
      hasMoreMap: {
        NotificationType.ALL: true,
        NotificationType.TRANSFER: true,
        NotificationType.CHAT: true,
        NotificationType.AI_MATCH: true,
        NotificationType.ITEM_REMINDER: true,
      },
      lastIdMap: {
        NotificationType.ALL: null,
        NotificationType.TRANSFER: null,
        NotificationType.CHAT: null,
        NotificationType.AI_MATCH: null,
        NotificationType.ITEM_REMINDER: null,
      },
    );
  }

  // 불변 상태 관리를 위한 복사본 생성
  NotificationState copyWith({
    Map<NotificationType, List<NotificationItem>>? notificationsMap,
    Map<NotificationType, bool>? isLoadingMap,
    Map<NotificationType, bool>? hasMoreMap,
    Map<NotificationType, int?>? lastIdMap,
  }) {
    return NotificationState(
      notificationsMap: notificationsMap ?? this.notificationsMap,
      isLoadingMap: isLoadingMap ?? this.isLoadingMap,
      hasMoreMap: hasMoreMap ?? this.hasMoreMap,
      lastIdMap: lastIdMap ?? this.lastIdMap,
    );
  }

  // 로딩 상태 업데이트
  NotificationState setLoading(NotificationType type, bool isLoading) {
    final newLoadingMap = Map<NotificationType, bool>.from(isLoadingMap);
    newLoadingMap[type] = isLoading;
    return copyWith(isLoadingMap: newLoadingMap);
  }

  // 특정 유형의 알림 데이터 업데이트
  NotificationState updateNotifications(
    NotificationType type,
    List<NotificationItem> items,
    bool hasMore, {
    bool append = true,
  }) {
    final newNotificationsMap =
        Map<NotificationType, List<NotificationItem>>.from(notificationsMap);
    final newHasMoreMap = Map<NotificationType, bool>.from(hasMoreMap);
    final newLastIdMap = Map<NotificationType, int?>.from(lastIdMap);

    if (append && items.isNotEmpty) {
      newNotificationsMap[type] = [...newNotificationsMap[type]!, ...items];
      if (items.isNotEmpty) {
        newLastIdMap[type] = items.last.id;
      }
    } else {
      newNotificationsMap[type] = items;
      newLastIdMap[type] = items.isNotEmpty ? items.last.id : null;
    }

    newHasMoreMap[type] = hasMore;

    return copyWith(
      notificationsMap: newNotificationsMap,
      hasMoreMap: newHasMoreMap,
      lastIdMap: newLastIdMap,
    );
  }

  // 알림 유형 상태 초기화
  NotificationState resetType(NotificationType type) {
    final newNotificationsMap =
        Map<NotificationType, List<NotificationItem>>.from(notificationsMap);
    final newHasMoreMap = Map<NotificationType, bool>.from(hasMoreMap);
    final newLastIdMap = Map<NotificationType, int?>.from(lastIdMap);

    newNotificationsMap[type] = [];
    newHasMoreMap[type] = true;
    newLastIdMap[type] = null;

    return copyWith(
      notificationsMap: newNotificationsMap,
      hasMoreMap: newHasMoreMap,
      lastIdMap: newLastIdMap,
    );
  }
}
