import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sumsumfinder/screens/chat/chat_room_page.dart';
import 'package:sumsumfinder/config/environment_config.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:intl/intl.dart';

class ChatRoom {
  final int id;
  final String opponentNickname;
  final String? latestMessage;
  final String? latestSentAt;
  final bool notificationEnabled;
  final FoundItem? foundItem;

  ChatRoom({
    required this.id,
    required this.opponentNickname,
    this.latestMessage,
    this.latestSentAt,
    required this.notificationEnabled,
    this.foundItem,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['chat_room_id'] ?? 0,
      opponentNickname: json['opponent_nickname'] ?? '알 수 없음',
      latestMessage: json['latest_message'],
      latestSentAt: json['latest_sent_at'],
      notificationEnabled: json['notification_enabled'] ?? true,
      foundItem:
          json['found_item'] != null
              ? FoundItem.fromJson(json['found_item'])
              : null,
    );
  }
}

class FoundItem {
  final int id;
  final Category category;
  final String name;
  final String color;
  final String? image;
  final String status;

  FoundItem({
    required this.id,
    required this.category,
    required this.name,
    required this.color,
    this.image,
    required this.status,
  });

  factory FoundItem.fromJson(Map<String, dynamic> json) {
    return FoundItem(
      id: json['id'] ?? 0,
      category: Category.fromJson(json['category'] ?? {}),
      name: json['name'] ?? '이름 없음',
      color: json['color'] ?? '',
      image: json['image'],
      status: json['status'] ?? 'UNKNOWN',
    );
  }
}

class Category {
  final int id;
  final String name;
  final int? parentId;
  final String? parentName;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.parentName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '카테고리 없음',
      parentId: json['parent_id'],
      parentName: json['parent_name'],
    );
  }
}

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final KakaoLoginService _loginService = KakaoLoginService();
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  String? _error;
  String _myUserName = ''; // 초기값은 비워두고 initState에서 설정

  // 채팅방 퇴장 API 추가
  Future<bool> leaveChatRoom(int chatRoomId) async {
    try {
      // 토큰 가져오기
      final token = await _loginService.getAccessToken();

      if (token == null) {
        return false;
      }

      // API 호출
      final response = await http.delete(
        Uri.parse(
          '${EnvironmentConfig.baseUrl}/api/chat-rooms/$chatRoomId/participants',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('채팅방 퇴장 API 응답 코드: ${response.statusCode}');
      final decodedBody = utf8.decode(response.bodyBytes);
      print('채팅방 퇴장 API 응답 본문: $decodedBody');

      // 204 No Content는 성공으로 처리
      return response.statusCode == 204;
    } catch (e) {
      print('채팅방 퇴장 중 오류: $e');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeUserName();
    _fetchChatRooms();
  }

  // 사용자 닉네임 초기화 (KakaoLoginService에서 직접 가져오기)
  Future<void> _initializeUserName() async {
    try {
      // 1. 먼저 저장된 사용자 프로필을 API로 가져오기 시도
      final userProfile = await _loginService.getUserProfile();
      if (userProfile != null && userProfile['profile_nickname'] != null) {
        setState(() {
          _myUserName = userProfile['profile_nickname'];
        });
        print('API에서 가져온 닉네임: $_myUserName');
        return;
      }

      // 2. API 실패 시 SharedPreferences에서 로드
      final prefs = await SharedPreferences.getInstance();
      final nickname = prefs.getString('user_nickname');
      if (nickname != null && nickname.isNotEmpty) {
        setState(() {
          _myUserName = nickname;
        });
        print('SharedPreferences에서 가져온 닉네임: $_myUserName');
        return;
      }

      // 3. 모두 실패할 경우 기본값 설정
      setState(() {
        _myUserName = '사용자';
      });
    } catch (e) {
      print('사용자 이름 초기화 중 오류: $e');
      setState(() {
        _myUserName = '사용자';
      });
    }
  }

  // 이전 _loadUserName 메서드 제거 (새로운 _initializeUserName으로 대체)

  // 채팅방 목록 가져오기
  Future<void> _fetchChatRooms() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 토큰 가져오기
      final token = await _loginService.getAccessToken();

      if (token == null) {
        setState(() {
          _error = '로그인이 필요합니다';
          _isLoading = false;
        });
        return;
      }

      // API 호출
      final response = await http.get(
        Uri.parse('${EnvironmentConfig.baseUrl}/api/chat-rooms/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept-Charset': 'utf-8', // UTF-8 인코딩 명시
        },
      );

      print('API 응답 코드: ${response.statusCode}');
      final decodedBody = utf8.decode(response.bodyBytes);
      print('API 응답 본문: $decodedBody');

      if (response.statusCode == 200) {
        // 한글 인코딩 문제 해결을 위한 처리
        final String decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = json.decode(decodedBody);

        if (data['success'] == true) {
          final List<dynamic> roomsData = data['data'] ?? [];
          setState(() {
            _chatRooms =
                roomsData
                    .map((roomData) => ChatRoom.fromJson(roomData))
                    .toList();
            _isLoading = false;
          });
          print('채팅방 ${_chatRooms.length}개를 성공적으로 로드했습니다.');
        } else {
          setState(() {
            _error = data['error'] ?? '채팅방 목록을 불러오는데 실패했습니다';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        // 토큰 갱신 시도
        final refreshed = await _loginService.refreshAccessToken();
        if (refreshed) {
          // 토큰 갱신 성공 시 다시 시도
          _fetchChatRooms();
          return;
        } else {
          setState(() {
            _error = '인증이 만료되었습니다. 다시 로그인해주세요.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = '서버 오류: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('채팅방 목록 가져오기 오류: $e');

      setState(() {
        _error = '연결 오류가 발생했습니다. 다시 시도해주세요.';
        _isLoading = false;
      });
    }
  }

  // 채팅 시간 포맷팅
  String formatChatTime(String? timeString) {
    if (timeString == null) return '시간 정보 없음';

    try {
      DateTime messageTime = DateTime.parse(timeString);
      DateTime now = DateTime.now();

      // 오늘 메시지인 경우 시간만 표시
      if (messageTime.year == now.year &&
          messageTime.month == now.month &&
          messageTime.day == now.day) {
        return DateFormat('HH:mm').format(messageTime);
      }

      // 어제 메시지인 경우
      DateTime yesterday = now.subtract(const Duration(days: 1));
      if (messageTime.year == yesterday.year &&
          messageTime.month == yesterday.month &&
          messageTime.day == yesterday.day) {
        return '어제';
      }

      // 올해 메시지인 경우 월/일 표시
      if (messageTime.year == now.year) {
        return DateFormat('MM/dd').format(messageTime);
      }

      // 작년 이전 메시지는 년/월/일 표시
      return DateFormat('yy/MM/dd').format(messageTime);
    } catch (e) {
      print('날짜 변환 오류: $e');
      return '시간 정보 오류';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '채팅',
        isFromBottomNav: true,
        customActions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchChatRooms,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchChatRooms,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_chatRooms.isEmpty) {
      return _buildEmptyChatList();
    }

    return RefreshIndicator(
      onRefresh: _fetchChatRooms,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.swipe_left, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '채팅방을 왼쪽으로 스와이프하여 나갈 수 있습니다',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _chatRooms.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final room = _chatRooms[index];
                return _buildChatRoomItem(room);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChatList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '진행 중인 채팅이 없습니다',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '습득물이나 분실물에 대해 대화를 시작해보세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _fetchChatRooms, child: const Text('새로고침')),
        ],
      ),
    );
  }

  Widget _buildChatRoomItem(ChatRoom room) {
    return Dismissible(
      key: Key('chat_room_${room.id}'),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.exit_to_app, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('채팅방 나가기'),
              content: const Text('이 채팅방에서 나가시겠습니까?\n새 메시지가 오면 다시 입장됩니다.'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('나가기'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        // 채팅방 퇴장 API 호출
        final success = await leaveChatRoom(room.id);

        if (success) {
          setState(() {
            _chatRooms.removeWhere((chatRoom) => chatRoom.id == room.id);
          });

          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('채팅방에서 나갔습니다')));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('채팅방 나가기에 실패했습니다')));
            // 실패 시 목록 다시 불러오기
            _fetchChatRooms();
          }
        }
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildChatRoomAvatar(room),
        title: Row(
          children: [
            Expanded(
              child: Text(
                room.opponentNickname,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!room.notificationEnabled)
              const Icon(Icons.notifications_off, size: 16, color: Colors.grey),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              room.latestMessage ?? '새로운 대화를 시작해보세요',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color:
                    room.latestMessage != null ? Colors.black87 : Colors.grey,
                fontSize: 13,
              ),
            ),
            if (room.foundItem != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _buildFoundItemTag(room.foundItem!),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatChatTime(room.latestSentAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
          ],
        ),
        onTap: () => _navigateToChatRoom(room),
      ),
    );
  }

  Widget _buildChatRoomAvatar(ChatRoom room) {
    String? imageUrl = room.foundItem?.image;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child:
            imageUrl != null
                ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  },
                )
                : Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.chat, color: Colors.grey),
                ),
      ),
    );
  }

  Widget _buildFoundItemTag(FoundItem item) {
    String statusText = '';
    Color statusColor = Colors.blue;

    switch (item.status) {
      case 'STORED':
        statusText = '보관중';
        statusColor = Colors.blue;
        break;
      case 'RECEIVED':
        statusText = '수령완료';
        statusColor = Colors.green;
        break;
      case 'TRANSFERRED':
        statusText = '이관됨';
        statusColor = Colors.orange;
        break;
      default:
        statusText = '상태미상';
        statusColor = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: statusColor.withOpacity(0.1),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_mall, size: 12, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            item.name,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ChatPage로 이동 메서드
  void _navigateToChatRoom(ChatRoom room) async {
    try {
      // 토큰 비동기적으로 가져오기
      final token = await _loginService.getAccessToken();

      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatPage(
                roomId: room.id,
                otherUserName: room.opponentNickname,
                myName: _myUserName,
              ),
        ),
      ).then((_) {
        // 채팅방에서 돌아오면 목록 갱신
        _fetchChatRooms();
      });
    } catch (e) {
      print('채팅방으로 이동 중 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('채팅방으로 이동 중 오류가 발생했습니다: $e')));
    }
  }
}
