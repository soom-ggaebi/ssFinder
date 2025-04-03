import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/services/notification_api_service.dart';
import 'package:sumsumfinder/models/noti_model.dart';
import 'package:sumsumfinder/utils/noti_state.dart';
import 'package:sumsumfinder/widgets/main/noti_item_widget.dart';

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
      _showErrorSnackBar('알림 데이터를 불러오는 중 오류가 발생했습니다');
    } finally {
      setState(() {
        _state = _state.setLoading(type, false);
      });
    }
  }

  // 모든 유형의 알림 데이터 로드
  Future<void> _loadAllNotifications(bool refresh) async {
    List<NotificationItem> allNotifications = [];
    bool hasMoreData = false;

    // 병렬로 각 타입별 API 호출
    final futures =
        [
          NotificationType.TRANSFER,
          NotificationType.CHAT,
          NotificationType.AI_MATCH,
          NotificationType.ITEM_REMINDER,
        ].map((apiType) async {
          try {
            final response = await NotificationApiService.getNotifications(
              type: apiType.apiValue,
              lastId: _state.lastIdMap[apiType],
            );

            if (response.success && response.data != null) {
              final items = response.data!.content;

              // 각 타입별 데이터 업데이트
              if (items.isNotEmpty) {
                setState(() {
                  _state = _state.updateNotifications(
                    apiType,
                    items,
                    response.data!.hasNext,
                    append: !refresh,
                  );
                });
              }

              // 전체 알림 목록에 추가
              allNotifications.addAll(items);

              // 더 불러올 데이터가 있는지 확인
              if (response.data!.hasNext) {
                hasMoreData = true;
              }
            }
          } catch (e) {
            print('${apiType.apiValue} 알림 로드 중 오류: $e');
          }
        }).toList();

    // 모든 API 호출 완료 대기
    await Future.wait(futures);

    // 날짜순으로 정렬 (최신순)
    allNotifications.sort(
      (a, b) => DateTime.parse(b.sendAt).compareTo(DateTime.parse(a.sendAt)),
    );

    // 전체 탭 데이터 업데이트
    setState(() {
      _state = _state.updateNotifications(
        NotificationType.ALL,
        allNotifications,
        hasMoreData,
        append: !refresh,
      );
    });
  }

  // 특정 유형의 알림 데이터 로드
  Future<void> _loadTypeNotifications(
    NotificationType type,
    bool refresh,
  ) async {
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
      _showErrorSnackBar(response.error!.message);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '알림 메시지',
        onBackPressed: () => Navigator.of(context).pop(),
        onClosePressed: () => Navigator.of(context).pop(),
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

                  // 알림 아이템
                  return NotificationItemWidget(
                    notification: notifications[index],
                  );
                },
              ),
    );
  }
}
