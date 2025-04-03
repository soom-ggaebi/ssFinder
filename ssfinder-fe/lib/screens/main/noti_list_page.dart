import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumsumfinder/config/environment_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// API 응답을 위한 모델 클래스들
class NotificationResponse {
  final bool success;
  final NotificationData? data;
  final ErrorData? error;
  final String timestamp;

  NotificationResponse({
    required this.success,
    this.data,
    this.error,
    required this.timestamp,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['success'],
      data:
          json['data'] != null ? NotificationData.fromJson(json['data']) : null,
      error: json['error'] != null ? ErrorData.fromJson(json['error']) : null,
      timestamp: json['timestamp'],
    );
  }
}

class NotificationData {
  final List<NotificationItem> content;
  final bool hasNext;

  NotificationData({required this.content, required this.hasNext});

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      content:
          (json['content'] as List)
              .map((item) => NotificationItem.fromJson(item))
              .toList(),
      hasNext: json['hasNext'],
    );
  }
}

class ErrorData {
  final String code;
  final String message;

  ErrorData({required this.code, required this.message});

  factory ErrorData.fromJson(Map<String, dynamic> json) {
    return ErrorData(code: json['code'], message: json['message']);
  }
}

// API 통신을 위한 서비스 클래스
class NotificationService {
  static final baseUrl = EnvironmentConfig.baseUrl;

  // 토큰 가져오기 함수 (SharedPreferences나 안전한 저장소에서 가져오기)
  // NotificationService 클래스에서
  static Future<String?> _getToken() async {
    const storage = FlutterSecureStorage();
    return await storage.read(key: 'access_token');
  }

  // 알림 데이터 가져오기
  static Future<NotificationResponse> getNotifications({
    required String type,
    int page = 0,
    int size = 10,
    int? lastId,
  }) async {
    try {
      print('알림 API 호출 시작: type=$type, page=$page, size=$size, lastId=$lastId');
      final token = await _getToken();
      if (token == null) {
        print('토큰이 없습니다. 로그인이 필요합니다.');
        throw Exception('로그인이 필요합니다');
      }

      print('사용할 토큰: ${token}'); // 보안을 위해 토큰 일부만 출력

      final queryParams = {
        'type': type,
        'page': page.toString(),
        'size': size.toString(),
      };

      if (lastId != null) {
        queryParams['lastId'] = lastId.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/api/notifications',
      ).replace(queryParameters: queryParams);

      print('요청 URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          // UTF-8 인코딩 설정
          'Accept-Charset': 'utf-8',
        },
      );

      print('응답 상태 코드: ${response.statusCode}');

      // 한국어 깨짐 방지를 위한 디코딩 처리
      String decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        print('API 호출 성공: ${decodedBody}');
        return NotificationResponse.fromJson(json.decode(decodedBody));
      } else {
        print('API 호출 실패: $decodedBody');
        // 에러 응답 처리
        try {
          return NotificationResponse.fromJson(json.decode(decodedBody));
        } catch (e) {
          print('API 응답 파싱 오류: $e');
          throw Exception('API 응답 처리 중 오류 발생: $decodedBody');
        }
      }
    } catch (e) {
      print('알림 데이터 가져오기 오류: $e');
      rethrow;
    }
  }
}

// 알림 유형 enum 추가
enum NotificationType { TRANSFER, CHAT, AI_MATCH, ITEM_REMINDER, ALL }

extension NotificationTypeExtension on NotificationType {
  String get apiValue {
    switch (this) {
      case NotificationType.TRANSFER:
        return 'TRANSFER';
      case NotificationType.CHAT:
        return 'CHAT';
      case NotificationType.AI_MATCH:
        return 'AI_MATCH';
      case NotificationType.ITEM_REMINDER:
        return 'ITEM_REMINDER';
      case NotificationType.ALL:
        return 'ALL'; // 실제 API에서는 처리해야 함
    }
  }
}

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final NotificationType type;
  final String sendAt;
  final bool isRead;
  final String? readAt;
  String? imagePath; // API에서 이미지 경로를 제공하지 않는 경우를 대비한 선택적 필드

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.sendAt,
    required this.isRead,
    this.readAt,
    this.imagePath,
  });

  // API 응답에서 NotificationItem 객체 생성
  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    NotificationType type;
    switch (json['type']) {
      case 'TRANSFER':
        type = NotificationType.TRANSFER;
        break;
      case 'CHAT':
        type = NotificationType.CHAT;
        break;
      case 'AI_MATCH':
        type = NotificationType.AI_MATCH;
        break;
      case 'ITEM_REMINDER':
        type = NotificationType.ITEM_REMINDER;
        break;
      default:
        type = NotificationType.ALL;
    }

    // 알림 유형에 따라 기본 이미지 설정
    String defaultImagePath;
    switch (type) {
      case NotificationType.TRANSFER:
        defaultImagePath = 'assets/images/chat/iphone_image.png';
        break;
      case NotificationType.CHAT:
        defaultImagePath = 'assets/images/chat/profile_image.png';
        break;
      case NotificationType.AI_MATCH:
        defaultImagePath = 'assets/images/chat/match_image.png';
        break;
      case NotificationType.ITEM_REMINDER:
        defaultImagePath = 'assets/images/chat/wallet_image.png';
        break;
      default:
        defaultImagePath = 'assets/images/chat/notification_default.png';
    }

    return NotificationItem(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: type,
      sendAt: json['send_at'],
      isRead: json['is_read'],
      readAt: json['read_at'],
      imagePath: defaultImagePath, // 기본 이미지 경로 설정
    );
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  // 탭 컨트롤러 및 탭 목록 추가
  late TabController _tabController;
  final List<String> _tabs = ['전체', '인계', '채팅', 'AI 매칭', '소지품'];
  final List<NotificationType> _tabTypes = [
    NotificationType.ALL,
    NotificationType.TRANSFER,
    NotificationType.CHAT,
    NotificationType.AI_MATCH,
    NotificationType.ITEM_REMINDER,
  ];

  // 카카오 로그인 서비스 인스턴스
  final _kakaoLoginService = KakaoLoginService();

  // 알림 설정 상태를 저장하는 변수들
  bool notificationTransfer = true;
  bool notificationChat = true;
  bool notificationAiMatch = true;
  bool notificationItemReminder = true;

  // 알림 데이터 관련 변수들
  Map<NotificationType, List<NotificationItem>> _notificationsMap = {
    NotificationType.ALL: [],
    NotificationType.TRANSFER: [],
    NotificationType.CHAT: [],
    NotificationType.AI_MATCH: [],
    NotificationType.ITEM_REMINDER: [],
  };

  Map<NotificationType, bool> _isLoadingMap = {
    NotificationType.ALL: false,
    NotificationType.TRANSFER: false,
    NotificationType.CHAT: false,
    NotificationType.AI_MATCH: false,
    NotificationType.ITEM_REMINDER: false,
  };

  Map<NotificationType, bool> _hasMoreMap = {
    NotificationType.ALL: true,
    NotificationType.TRANSFER: true,
    NotificationType.CHAT: true,
    NotificationType.AI_MATCH: true,
    NotificationType.ITEM_REMINDER: true,
  };

  Map<NotificationType, int?> _lastIdMap = {
    NotificationType.ALL: null,
    NotificationType.TRANSFER: null,
    NotificationType.CHAT: null,
    NotificationType.AI_MATCH: null,
    NotificationType.ITEM_REMINDER: null,
  };

  @override
  void initState() {
    super.initState();
    // 탭 컨트롤러 초기화
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);

    // 로그인 상태 확인 및 비로그인 시 자동 뒤로가기
    _checkLoginStatus();

    // 알림 설정 상태 로드
    _loadNotificationSettings();

    // 초기 탭(전체)의 알림 데이터 로드
    _loadNotifications(NotificationType.ALL);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  // 탭 변경 이벤트 처리
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final type = _tabTypes[_tabController.index];
      // 해당 탭의 데이터가 비어있으면 로드
      if (_notificationsMap[type]!.isEmpty && _hasMoreMap[type]!) {
        _loadNotifications(type);
      }
    }
  }

  // 알림 설정 상태 로드
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        // 개별 알림 설정 상태 로드
        notificationTransfer = prefs.getBool('notification_TRANSFER') ?? true;
        notificationChat = prefs.getBool('notification_CHAT') ?? true;
        notificationAiMatch = prefs.getBool('notification_AI_MATCH') ?? true;
        notificationItemReminder =
            prefs.getBool('notification_ITEM_REMINDER') ?? true;
      });
    } catch (e) {
      print('알림 설정 로드 중 오류: $e');
    }
  }

  // 로그인 상태 확인 및 비로그인 시 뒤로가기
  // 디버깅을 위해 토큰 값 확인
  void _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    print('저장된 토큰: $token');

    // 로그인 되어 있지 않으면 바로 뒤로가기
    if (!_kakaoLoginService.isLoggedIn.value) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pop();
      });
    }
  }

  // API를 통해 알림 데이터 로드
  Future<void> _loadNotifications(
    NotificationType type, {
    bool refresh = false,
  }) async {
    // 이미 로딩 중이거나 더 이상 데이터가 없는 경우 무시
    if (_isLoadingMap[type]! || (!refresh && !_hasMoreMap[type]!)) {
      return;
    }

    setState(() {
      _isLoadingMap[type] = true;
    });

    try {
      // 새로고침 시 기존 데이터 초기화
      if (refresh) {
        _lastIdMap[type] = null;

        setState(() {
          _notificationsMap[type] = [];
          _hasMoreMap[type] = true;
        });
      }

      // ALL 타입일 경우 4가지 타입의 알림을 모두 불러오기
      if (type == NotificationType.ALL) {
        // 각 타입별로 알림 로드
        List<NotificationItem> allNotifications = [];
        bool hasMoreData = false;

        // 병렬로 모든 API 호출 실행
        final futures =
            [
              NotificationType.TRANSFER,
              NotificationType.CHAT,
              NotificationType.AI_MATCH,
              NotificationType.ITEM_REMINDER,
            ].map((apiType) async {
              try {
                final response = await NotificationService.getNotifications(
                  type: apiType.apiValue,
                  lastId: _lastIdMap[apiType],
                );

                if (response.success && response.data != null) {
                  // 해당 타입의 데이터 저장
                  if (response.data!.content.isNotEmpty) {
                    _lastIdMap[apiType] = response.data!.content.last.id;

                    // 타입별 탭에도 데이터 추가
                    setState(() {
                      final typeItems = List<NotificationItem>.from(
                        _notificationsMap[apiType]!,
                      );
                      typeItems.addAll(response.data!.content);
                      _notificationsMap[apiType] = typeItems;
                      _hasMoreMap[apiType] = response.data!.hasNext;
                    });
                  }

                  // 전체 알림 목록에 추가
                  allNotifications.addAll(response.data!.content);

                  // 하나라도 더 불러올 데이터가 있으면 true
                  if (response.data!.hasNext) {
                    hasMoreData = true;
                  }
                }
              } catch (e) {
                print('${apiType.apiValue} 알림 로드 중 오류: $e');
              }
              return;
            }).toList();

        // 모든 API 호출이 완료될 때까지 대기
        await Future.wait(futures);

        // 날짜순으로 정렬 (최신순)
        allNotifications.sort(
          (a, b) =>
              DateTime.parse(b.sendAt).compareTo(DateTime.parse(a.sendAt)),
        );

        // 전체 탭에 저장
        setState(() {
          final currentItems = List<NotificationItem>.from(
            _notificationsMap[NotificationType.ALL]!,
          );
          currentItems.addAll(allNotifications);
          _notificationsMap[NotificationType.ALL] = currentItems;
          _hasMoreMap[NotificationType.ALL] = hasMoreData;
        });
      } else {
        // 특정 탭의 경우 해당 타입만 API 호출
        final response = await NotificationService.getNotifications(
          type: type.apiValue,
          lastId: _lastIdMap[type],
        );

        if (response.success && response.data != null) {
          final newItems = response.data!.content;
          final typeItems = List<NotificationItem>.from(
            _notificationsMap[type]!,
          );
          typeItems.addAll(newItems);

          setState(() {
            _notificationsMap[type] = typeItems;
            _hasMoreMap[type] = response.data!.hasNext;
          });

          // 다음 페이지 로드를 위한 마지막 ID
          if (newItems.isNotEmpty) {
            _lastIdMap[type] = newItems.last.id;
          }
        } else if (response.error != null) {
          _showErrorSnackBar(response.error!.message);
        }
      }
    } catch (e) {
      _showErrorSnackBar('알림 데이터를 불러오는 중 오류가 발생했습니다: $e');
    } finally {
      setState(() {
        _isLoadingMap[type] = false;
      });
    }
  }

  // 에러 메시지 스낵바 표시
  void _showErrorSnackBar(String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // 데이터 새로고침 처리
  Future<void> _refreshCurrentTab() async {
    final currentType = _tabTypes[_tabController.index];
    await _loadNotifications(currentType, refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
              tabs: _tabs.map((e) => Tab(text: e)).toList(),
            ),
          ),
          // 탭 내용
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (index) {
                final type = _tabTypes[index];
                return _buildTabContent(type);
              }),
            ),
          ),
        ],
      ),
    );
  }

  /// 각 탭에 해당하는 목록을 보여주는 위젯
  Widget _buildTabContent(NotificationType type) {
    final notifications = _notificationsMap[type]!;
    final isLoading = _isLoadingMap[type]!;
    final hasMore = _hasMoreMap[type]!;

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

class NotificationItemWidget extends StatelessWidget {
  final NotificationItem notification;

  const NotificationItemWidget({Key? key, required this.notification})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 알림 날짜 포맷팅
    final formattedDate = _formatDateTime(notification.sendAt);

    // 알림 타입에 따른 하이라이트 여부
    final isHighlighted = notification.type == NotificationType.TRANSFER;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFE9F1FF),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF4F4F4F), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제품 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              notification.imagePath ??
                  'assets/images/chat/notification_default.png',
              width: 95,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.notifications, color: Colors.grey),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          // 텍스트 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 2),
                // subtitle 대신 type 기반 텍스트 표시
                Text(_getSubtitleByType(notification.type)),
                const SizedBox(height: 6),
                Text(
                  notification.body,
                  style: TextStyle(
                    color: isHighlighted ? Colors.red : const Color(0xFF3D3D3D),
                    fontWeight:
                        isHighlighted ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 알림 타입에 따른 부제목 생성
  String _getSubtitleByType(NotificationType type) {
    switch (type) {
      case NotificationType.TRANSFER:
        return '인계 알림';
      case NotificationType.CHAT:
        return '채팅 알림';
      case NotificationType.AI_MATCH:
        return 'AI 매칭 알림';
      case NotificationType.ITEM_REMINDER:
        return '소지품 알림';
      default:
        return '알림';
    }
  }

  // 날짜 시간 포맷팅
  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();

      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return '방금 전';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return '${dateTime.year}.${dateTime.month}.${dateTime.day}';
      }
    } catch (e) {
      return dateTimeStr;
    }
  }
}
