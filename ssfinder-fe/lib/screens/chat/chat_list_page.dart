import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sumsumfinder/screens/chat/chat_room_page.dart'; // 수정된 ChatPage 임포트
import 'package:sumsumfinder/config/environment_config.dart'; // 환경 설정 임포트
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart'; // KakaoLoginService 임포트 추가

class ChatRoom {
  final int id;
  final String otherUserName;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final String? productImage;

  ChatRoom({
    required this.id,
    required this.otherUserName,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.productImage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['room_id'] ?? 0,
      otherUserName: json['other_user_nickname'] ?? '알 수 없음',
      lastMessage: json['last_message'] ?? '',
      lastMessageTime: json['last_message_time'] ?? '방금 전',
      unreadCount: json['unread_count'] ?? 0,
      productImage: json['product_image'],
    );
  }
}

class ChatListPage extends StatefulWidget {
  // jwt 파라미터 제거
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final KakaoLoginService _loginService = KakaoLoginService(); // 서비스 인스턴스 추가
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;
  String? _error;
  String _myUserName = '기다리는 토마토'; // 기본값

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
    _loadUserName();
  }

  // 사용자 닉네임 로드
  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nickname = prefs.getString('user_nickname');
      if (nickname != null && nickname.isNotEmpty) {
        setState(() {
          _myUserName = nickname;
        });
      }
    } catch (e) {
      print('사용자 이름 로드 중 오류: $e');
    }
  }

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

      final response = await http.get(
        Uri.parse('${EnvironmentConfig.baseUrl}/api/chat-rooms'),
        headers: {
          'Authorization': 'Bearer $token', // widget.jwt 대신 토큰 사용
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['success'] == true) {
          final List<dynamic> roomsData = data['data'] ?? [];
          setState(() {
            _chatRooms =
                roomsData
                    .map((roomData) => ChatRoom.fromJson(roomData))
                    .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['error'] ?? '채팅방 목록을 불러오는데 실패했습니다';
            _isLoading = false;
          });
        }
      } else {
        // API 서버가 아직 준비되지 않은 경우를 위한 테스트 데이터
        setState(() {
          _chatRooms = [
            ChatRoom(
              id: 1,
              otherUserName: '기어가는 초콜릿',
              lastMessage: '안녕하세요, 물건 좀 물어봐도 될까요?',
              lastMessageTime: '10:30',
              unreadCount: 2,
              productImage: 'https://via.placeholder.com/50',
            ),
            ChatRoom(
              id: 2,
              otherUserName: '달리는 사과',
              lastMessage: '거래 완료되었습니다. 감사합니다!',
              lastMessageTime: '어제',
              unreadCount: 0,
              productImage: 'https://via.placeholder.com/50',
            ),
          ];
          _isLoading = false;
        });

        print('API 응답 오류: ${response.statusCode}');
        print('API 응답 본문: ${response.body}');
      }
    } catch (e) {
      print('채팅방 목록 가져오기 오류: $e');

      // 네트워크 오류 등의 경우에도 테스트 데이터 사용
      setState(() {
        _error = '연결 오류가 발생했습니다. 다시 시도해주세요.';
        _isLoading = false;

        // 오류 발생시 테스트 데이터로 UI 표시 (개발 편의를 위해)
        _chatRooms = [
          ChatRoom(
            id: 1,
            otherUserName: '기어가는 초콜릿',
            lastMessage: '안녕하세요, 물건 좀 물어봐도 될까요?',
            lastMessageTime: '10:30',
            unreadCount: 2,
            productImage: 'https://via.placeholder.com/50',
          ),
          ChatRoom(
            id: 2,
            otherUserName: '달리는 사과',
            lastMessage: '거래 완료되었습니다. 감사합니다!',
            lastMessageTime: '어제',
            unreadCount: 0,
            productImage: 'https://via.placeholder.com/50',
          ),
        ];
      });
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
      return const Center(child: Text('진행 중인 채팅이 없습니다.'));
    }

    return ListView.separated(
      itemCount: _chatRooms.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final room = _chatRooms[index];
        return _buildChatRoomItem(room);
      },
    );
  }

  Widget _buildChatRoomItem(ChatRoom room) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Colors.grey[200],
        backgroundImage:
            room.productImage != null ? NetworkImage(room.productImage!) : null,
        child:
            room.productImage == null
                ? const Icon(Icons.chat, color: Colors.grey)
                : null,
      ),
      title: Text(
        room.otherUserName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        room.lastMessage,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            room.lastMessageTime,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          if (room.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                room.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: () => _navigateToChatRoom(room),
    );
  }

  void _navigateToChatRoom(ChatRoom room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ChatPage(
              roomId: room.id,
              otherUserName: room.otherUserName,
              myName: _myUserName,
            ),
      ),
    );
  }
}
