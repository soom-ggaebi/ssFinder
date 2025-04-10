// pages/notification_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/services/notification_api_service.dart';
import 'package:sumsumfinder/models/noti_model.dart';
import 'package:sumsumfinder/utils/noti_state.dart';
import 'package:sumsumfinder/widgets/main/noti_item_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/screens/home_page.dart';
import 'package:sumsumfinder/utils/time_formatter.dart'; // TimeFormatter import 추가

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  // 탭 컨트롤러 및 탭 목록
  late TabController _tabController;
  final List<String> _tabLabels = ['전체', '인계', '채팅', 'AI 매칭', '소지품'];
  final List<NotificationType> _tabTypes = [
    NotificationType.ALL,
    NotificationType.TRANSFER,
    NotificationType.CHAT,
    NotificationType.AI_MATCH,
    NotificationType.ITEM_REMINDER,
  ];

  // 카카오 로그인 서비스
  final _kakaoLoginService = KakaoLoginService();

  // 알림 설정 상태
  final Map<NotificationType, bool> _notificationSettings = {
    NotificationType.TRANSFER: true,
    NotificationType.CHAT: true,
    NotificationType.AI_MATCH: true,
    NotificationType.ITEM_REMINDER: true,
  };

  // 알림 상태 관리
  late NotificationState _state;

  @override
  void initState() {
    super.initState();
    _state = NotificationState.initial();

    // 탭 컨트롤러 초기화
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    // 로그인 상태 확인 및 데이터 로드
    _checkLoginStatus();
    _loadNotificationSettings();
    _loadNotifications(NotificationType.ALL);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // 탭 변경 핸들러
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final type = _tabTypes[_tabController.index];
      if (_state.notificationsMap[type]!.isEmpty && _state.hasMoreMap[type]!) {
        _loadNotifications(type);
      }
    }
  }

  // 알림 설정 로드
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationSettings[NotificationType.TRANSFER] =
            prefs.getBool('notification_TRANSFER') ?? true;
        _notificationSettings[NotificationType.CHAT] =
            prefs.getBool('notification_CHAT') ?? true;
        _notificationSettings[NotificationType.AI_MATCH] =
            prefs.getBool('notification_AI_MATCH') ?? true;
        _notificationSettings[NotificationType.ITEM_REMINDER] =
            prefs.getBool('notification_ITEM_REMINDER') ?? true;
      });
    } catch (e) {
      _showErrorSnackBar('알림 설정을 로드하는 중 오류가 발생했습니다');
    }
  }

  // 로그인 상태 확인
  void _checkLoginStatus() async {
    if (!_kakaoLoginService.isLoggedIn.value) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pop();
      });
    }
  }

  // 알림 데이터 로드
  Future<void> _loadNotifications(
    NotificationType type, {
    bool refresh = false,
  }) async {
    // 이미 로딩 중이거나 더 이상 데이터가 없는 경우 무시
    if (_state.isLoadingMap[type]! || (!refresh && !_state.hasMoreMap[type]!)) {
      return;
    }

    setState(() {
      _state = _state.setLoading(type, true);
    });

    try {
      // 새로고침 시 상태 초기화
      if (refresh) {
        setState(() {
          _state = _state.resetType(type);
        });
      }

      if (type == NotificationType.ALL) {
        await _loadAllNotifications(refresh);
      } else {
        await _loadTypeNotifications(type, refresh);
      }
    } catch (e) {
      print('알림 데이터 로드 중 오류: $e');

      // 로그인 관련 오류인 경우 특별 처리
      if (e.toString().contains('로그인이 필요합니다')) {
        _showErrorSnackBar('로그인이 필요합니다');
        _navigateToLogin();
      } else {
        _showErrorSnackBar('알림 데이터를 불러오는 중 오류가 발생했습니다');
      }
    } finally {
      setState(() {
        _state = _state.setLoading(type, false);
      });
    }
  }

  // 특정 유형의 알림 데이터 로드
  Future<void> _loadTypeNotifications(
    NotificationType type,
    bool refresh,
  ) async {
    try {
      // 로그인 상태 확인 추가
      final token = await _kakaoLoginService.getAccessToken();
      if (token == null) {
        _showErrorSnackBar('로그인이 필요합니다');
        _navigateToLogin();
        return;
      }

      final response = await NotificationApiService.getNotifications(
        type: type.apiValue,
        lastId: _state.lastIdMap[type],
      );

      if (response.success && response.data != null) {
        setState(() {
          _state = _state.updateNotifications(
            type,
            response.data!.content,
            response.data!.hasNext,
            append: !refresh,
          );
        });
      } else if (response.error != null) {
        // 로그인 관련 오류인지 확인
        if (response.error!.message.contains('로그인') ||
            response.error!.code == 'UNAUTHORIZED') {
          _showErrorSnackBar('로그인이 필요합니다');
          _navigateToLogin();
        } else {
          _showErrorSnackBar(response.error!.message);
        }
      }
    } catch (e) {
      print('타입별 알림 로드 중 오류: $e');
      // 로그인 관련 오류인 경우 특별 처리
      if (e.toString().contains('로그인이 필요합니다')) {
        _showErrorSnackBar('로그인이 필요합니다');
        _navigateToLogin();
      } else {
        _showErrorSnackBar('알림 데이터를 불러오는 중 오류가 발생했습니다');
      }
    }
  }

  // 모든 유형의 알림 데이터 로드 - 개선 버전
  Future<void> _loadAllNotifications(bool refresh) async {
    try {
      // 로그인 상태 확인 추가
      final token = await _kakaoLoginService.getAccessToken();
      if (token == null) {
        _showErrorSnackBar('로그인이 필요합니다');
        _navigateToLogin(); // 로그인 페이지로 이동하는 함수 추가
        return;
      }

      // ALL 타입 API를 사용하여 모든 알림을 한 번에 가져옴
      final response = await NotificationApiService.getNotifications(
        // type 파라미터를 전달하지 않음 (모든 타입 가져오기)
        lastId: _state.lastIdMap[NotificationType.ALL],
      );

      if (response.success && response.data != null) {
        // 기존 코드 유지
        final items = response.data!.content;
        final hasMore = response.data!.hasNext;

        // 전체 탭에 데이터 추가
        setState(() {
          _state = _state.updateNotifications(
            NotificationType.ALL,
            items,
            hasMore,
            append: !refresh,
          );
        });

        // 각 타입별 알림을 필터링하여 해당 탭에도 저장
        if (items.isNotEmpty) {
          // 타입별로 알림 분류
          Map<NotificationType, List<NotificationItem>> typeGroupedItems = {};

          for (var type in [
            NotificationType.TRANSFER,
            NotificationType.CHAT,
            NotificationType.AI_MATCH,
            NotificationType.ITEM_REMINDER,
          ]) {
            typeGroupedItems[type] =
                items.where((item) => item.type == type).toList();
          }

          // 각 타입별 탭 데이터 업데이트
          setState(() {
            for (var type in typeGroupedItems.keys) {
              if (typeGroupedItems[type]!.isNotEmpty) {
                _state = _state.updateNotifications(
                  type,
                  typeGroupedItems[type]!,
                  hasMore, // 모든 탭에 동일한 hasMore 값 사용
                  append: !refresh,
                );
              }
            }
          });
        }
      } else if (response.error != null) {
        // 로그인 관련 오류인지 확인
        if (response.error!.message.contains('로그인') ||
            response.error!.code == 'UNAUTHORIZED') {
          _showErrorSnackBar('로그인이 필요합니다');
          _navigateToLogin(); // 로그인 페이지로 이동
        } else {
          _showErrorSnackBar(response.error!.message);
        }
      }
    } catch (e) {
      print('전체 알림 로드 중 오류: $e');
      // 로그인 관련 오류인 경우 특별 처리
      if (e.toString().contains('로그인이 필요합니다')) {
        _showErrorSnackBar('로그인이 필요합니다');
        _navigateToLogin(); // 로그인 페이지로 이동
      } else {
        _showErrorSnackBar('알림 데이터를 불러오는 중 오류가 발생했습니다');
      }
    }
  }

  // 로그인 페이지로 이동하는 대신 카카오 로그인 시도
  void _navigateToLogin() {
    Future.delayed(Duration.zero, () async {
      if (mounted) {
        // 로그인 시도 중 다이얼로그 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        try {
          // 카카오 로그인 시도
          final success = await _kakaoLoginService.loginWithBackendAuth();

          // 로딩 다이얼로그 닫기
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          if (success) {
            // 로그인 성공 시 알림 데이터 다시 로드
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그인 성공! 알림을 불러옵니다.')),
              );
              _refreshCurrentTab();
            }
          } else {
            // 로그인 실패 시 에러 메시지
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')),
              );
              // 로그인 실패 시 이전 화면으로 돌아가기
              Navigator.of(context).pop();
            }
          }
        } catch (e) {
          // 예외 발생 시 로딩 다이얼로그 닫기
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }

          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('로그인 중 오류가 발생했습니다: $e')));
            // 오류 발생 시 이전 화면으로 돌아가기
            Navigator.of(context).pop();
          }
        }
      }
    });
  }

  // 에러 메시지 표시
  void _showErrorSnackBar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // 현재 탭 새로고침
  Future<void> _refreshCurrentTab() async {
    final currentType = _tabTypes[_tabController.index];
    await _loadNotifications(currentType, refresh: true);
  }

  // 전체 삭제 확인 다이얼로그 표시
  void _showDeleteAllConfirmation() {
    final currentType = _tabTypes[_tabController.index];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('전체 알림 삭제'),
            content: Text(
              '${_tabLabels[_tabController.index]} 알림을 모두 삭제하시겠습니까?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteAllNotifications(currentType);
                },
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }

  // 전체 알림 삭제 처리
  Future<void> _deleteAllNotifications(NotificationType type) async {
    // ALL 타입은 API에서 지원하지 않을 수 있으므로 별도 처리
    if (type == NotificationType.ALL) {
      // 모든 타입에 대해 각각 삭제 요청
      bool allSuccess = true;

      for (var subType in [
        NotificationType.TRANSFER,
        NotificationType.CHAT,
        NotificationType.AI_MATCH,
        NotificationType.ITEM_REMINDER,
      ]) {
        final success = await NotificationApiService.deleteAllNotifications(
          subType.apiValue,
        );
        if (!success) allSuccess = false;
      }

      if (allSuccess) {
        // 모든 타입의 알림 로컬 상태에서 제거
        setState(() {
          for (var t in NotificationType.values) {
            final newNotificationsMap =
                Map<NotificationType, List<NotificationItem>>.from(
                  _state.notificationsMap,
                );
            newNotificationsMap[t] = [];
            _state = _state.copyWith(notificationsMap: newNotificationsMap);
          }
        });
      } else {
        _showErrorSnackBar('일부 알림을 삭제하지 못했습니다.');
        _refreshCurrentTab();
      }
    } else {
      // 특정 타입에 대한 삭제 요청
      final success = await NotificationApiService.deleteAllNotifications(
        type.apiValue,
      );

      if (success) {
        // 해당 타입과 ALL 탭의 해당 타입 알림 로컬 상태에서 제거
        setState(() {
          // 해당 타입 탭 비우기
          final typeNotificationsMap =
              Map<NotificationType, List<NotificationItem>>.from(
                _state.notificationsMap,
              );
          typeNotificationsMap[type] = [];

          // ALL 탭에서 해당 타입 제거
          final allNotifications = List<NotificationItem>.from(
            _state.notificationsMap[NotificationType.ALL] ?? [],
          );
          allNotifications.removeWhere((item) => item.type == type);
          typeNotificationsMap[NotificationType.ALL] = allNotifications;

          _state = _state.copyWith(notificationsMap: typeNotificationsMap);
        });
      } else {
        _showErrorSnackBar('알림을 삭제하지 못했습니다.');
        _refreshCurrentTab();
      }
    }
  }

  // 알림 삭제 메서드 (여기에 추가)
  Future<void> _deleteNotification(NotificationItem notification) async {
    // API를 통해 서버에서 알림 삭제
    final success = await NotificationApiService.deleteNotification(
      notification.id,
    );

    if (success) {
      // 성공 시 로컬 상태에서도 알림 삭제
      for (var type in NotificationType.values) {
        final notifications = List<NotificationItem>.from(
          _state.notificationsMap[type] ?? [],
        );
        notifications.removeWhere((item) => item.id == notification.id);

        setState(() {
          final newNotificationsMap =
              Map<NotificationType, List<NotificationItem>>.from(
                _state.notificationsMap,
              );
          newNotificationsMap[type] = notifications;
          _state = _state.copyWith(notificationsMap: newNotificationsMap);
        });
      }
    } else {
      // 삭제 실패 시 사용자에게 알림
      if (context.mounted) {
        _showErrorSnackBar('알림을 삭제할 수 없습니다.');
      }

      // 실패 시 UI 갱신 (삭제된 아이템이 다시 나타나도록)
      _refreshCurrentTab();
    }
  }

  // 알림을 클릭할 때 호출되는 메서드
  void _handleNotificationTap(NotificationItem notification) async {
    print(
      'NotificationPage: Handling tap for ${notification.id}, type: ${notification.type}',
    );

    try {
      // 알림 탭 시 먼저 알림 읽음 처리 및 삭제
      final success = await NotificationApiService.deleteNotification(
        notification.id,
      );

      // 알림 타입에 따라 다른 페이지로 이동
      switch (notification.type) {
        case NotificationType.CHAT:
          print('NotificationPage: Navigating to ChatListPage with bottom nav');

          // HomePage로 이동하면서 채팅 탭(인덱스 3)을 선택
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomePage(initialIndex: 3), // 채팅 탭 인덱스는 3
            ),
            (route) => false, // 모든 이전 라우트 제거
          );
          break;
        case NotificationType.TRANSFER:
          print(
            'NotificationPage: Transfer notification tapped (not implemented)',
          );
          // TODO: 인계 관련 페이지로 이동
          break;
        case NotificationType.AI_MATCH:
          print(
            'NotificationPage: AI Match notification tapped (not implemented)',
          );
          // TODO: AI 매칭 관련 페이지로 이동
          break;
        case NotificationType.ITEM_REMINDER:
          print(
            'NotificationPage: Item Reminder notification tapped (not implemented)',
          );
          // TODO: 소지품 관련 페이지로 이동
          break;
        default:
          print('NotificationPage: Unknown notification type');
          break;
      }
    } catch (e) {
      print('NotificationPage: Error handling notification tap: $e');
      _showErrorSnackBar('알림 처리 중 오류가 발생했습니다: $e');
    }
  }

  // 알림을 읽음 처리하고 삭제하는 메서드
  Future<void> _markAsReadAndDelete(NotificationItem notification) async {
    try {
      // 읽음 처리 API 호출 (이 부분은 서버에 읽음 상태를 업데이트하는 API가 있다면 호출)
      // 예: await NotificationApiService.markAsRead(notification.id);

      // 알림 삭제 API 호출
      final success = await NotificationApiService.deleteNotification(
        notification.id,
      );

      if (success) {
        // 성공 시 로컬 상태에서도 알림 삭제
        for (var type in NotificationType.values) {
          final notifications = List<NotificationItem>.from(
            _state.notificationsMap[type] ?? [],
          );
          notifications.removeWhere((item) => item.id == notification.id);

          setState(() {
            final newNotificationsMap =
                Map<NotificationType, List<NotificationItem>>.from(
                  _state.notificationsMap,
                );
            newNotificationsMap[type] = notifications;
            _state = _state.copyWith(notificationsMap: newNotificationsMap);
          });
        }
      } else {
        // 삭제 실패 시 에러 발생
        throw Exception('알림 삭제 실패');
      }
    } catch (e) {
      print('알림 읽음 처리 및 삭제 중 오류: $e');
      // 오류가 발생해도 페이지 이동은 계속 진행
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '알림 메시지',
        isFromBottomNav: false,
        customActions: [
          Center(
            child: SizedBox(
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/images/common/appBar/delete_button.svg',
                ),
                onPressed: _showDeleteAllConfirmation,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 탭바
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
              tabs: _tabLabels.map((e) => Tab(text: e)).toList(),
            ),
          ),

          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabLabels.length, (index) {
                final type = _tabTypes[index];
                return _buildTabContent(type);
              }),
            ),
          ),
        ],
      ),
    );
  }

  // 탭 내용 위젯 빌드
  // NotificationPage의 _buildTabContent 메서드 수정
  Widget _buildTabContent(NotificationType type) {
    final notifications = _state.notificationsMap[type]!;
    final isLoading = _state.isLoadingMap[type]!;
    final hasMore = _state.hasMoreMap[type]!;

    return RefreshIndicator(
      onRefresh: _refreshCurrentTab,
      child:
          isLoading && notifications.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? const Center(
                child: Text(
                  '알림이 없습니다',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
              : ListView.separated(
                itemCount:
                    notifications.length + (isLoading || hasMore ? 1 : 0),
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  // 로딩 인디케이터 또는 더 불러오기 버튼
                  if (index == notifications.length) {
                    if (isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    } else if (hasMore) {
                      return Center(
                        child: TextButton(
                          onPressed: () => _loadNotifications(type),
                          child: const Text('더 불러오기'),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  // 알림 아이템 - 외부 콜백으로 탭 이벤트 위임
                  final notification = notifications[index];

                  return NotificationItemWidget(
                    notification: notification,
                    onDelete: _deleteNotification,
                    onTap: _handleNotificationTap, // 외부 콜백 전달
                  );
                },
              ),
    );
  }
}
