import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sumsumfinder/config/environment_config.dart';
import 'package:sumsumfinder/models/chat_message.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';

class ChatService {
  final Dio _dio = Dio();
  final String baseUrl = EnvironmentConfig.baseUrl;
  int? _currentUserId;

  /// 초기화: 사용자 ID 미리 가져오기
  Future<void> initialize() async {
    _currentUserId = await KakaoLoginService().getUserId();
  }

  /// ─────────────────────────────────────────────────────────────
  /// 이미지 업로드
  Future<ChatMessage?> uploadImage(
    File imageFile,
    int chatRoomId,
    int? senderId,
    String token,
  ) async {
    if (senderId == null) {
      print('이미지 업로드 실패: 유효한 사용자 ID가 없습니다.');
      return null;
    }

    try {
      final now = DateTime.now();

      // FormData 생성
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      // 헤더 설정
      _dio.options.headers = {'Authorization': 'Bearer $token'};

      print('업로드 URL: $baseUrl/api/chat-rooms/$chatRoomId/upload');
      print('토큰: Bearer $token');

      // API 요청
      final response = await _dio.post(
        '$baseUrl/api/chat-rooms/$chatRoomId/upload',
        data: formData,
      );

      print('이미지 업로드 응답: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        String content = response.data['data']['content'];
        // 불필요한 꺽쇠 제거
        if (content.startsWith('<') && content.endsWith('>')) {
          content = content.substring(1, content.length - 1);
        }

        return ChatMessage(
          text: '',
          isSent: true,
          sentAt: now,
          imageUrl: content,
          type: 'IMAGE',
          status: 'SENT',
          messageId: response.data['data']['message_id'] as String?,
        );
      } else {
        print('이미지 업로드 실패: ${response.data}');
      }
    } catch (e) {
      print('이미지 업로드 중 오류 발생: $e');
    }
    return null;
  }

  /// ─────────────────────────────────────────────────────────────
  /// 메시지 불러오기 (API)
  Future<List<ChatMessage>> loadMessages(
    int chatRoomId, {
    int size = 20,
    String? cursor,
    int? userId,
    bool forceRefresh = false,
  }) async {
    // API 호출 차단 체크
    final isBlocked = await isApiBlocked(chatRoomId);
    if (!forceRefresh && isBlocked) {
      print('API 호출이 차단되어 있습니다.');
      return [];
    }

    // 토큰 & 사용자 ID 확보
    final token = await KakaoLoginService().getAccessToken();
    if (token == null) return [];
    int? currentUserId = userId ?? _currentUserId ?? await KakaoLoginService().getUserId();
    if (currentUserId == null) return [];

    // URL 구성
    String url = '$baseUrl/api/chat-rooms/$chatRoomId/messages?size=$size';
    if (cursor != null && cursor.isNotEmpty) {
      url += '&cursor=$cursor';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body) as Map<String, dynamic>;
      if (data['success'] == true) {
        // 다음 커서 저장
        final nextCursor = data['data']['nextCursor'] as String?;
        if (nextCursor != null) {
          await _saveNextCursor(chatRoomId, nextCursor);
        }

        // 메시지 파싱
        final rawList = data['data']['messages'] as List<dynamic>;
        final messages = rawList
            .map((e) => _convertToMessage(e as Map<String, dynamic>, currentUserId))
            .toList();

        // DateTime 순으로 정렬
        return _sortMessagesByTime(messages);
      }
    } else {
      print('메시지 로드 실패: ${response.statusCode}');
    }
    return [];
  }

  /// ─────────────────────────────────────────────────────────────
  /// ChatMessage 로 변환 (ISO → DateTime)
  ChatMessage _convertToMessage(
    Map<String, dynamic> data,
    int currentUserId,
  ) {
    // sent_at 파싱
    DateTime sentAt;
    try {
      sentAt = DateTime.parse(data['sent_at'] as String);
    } catch (_) {
      sentAt = DateTime.now();
    }

    final type = data['type'] as String? ?? 'NORMAL';
    final content = data['content'] as String? ?? '';

    return ChatMessage(
      text: (type == 'IMAGE' || type == 'LOCATION') ? '' : content,
      isSent: data['sender_id'] == currentUserId,
      sentAt: sentAt,
      type: type,
      status: data['status'] as String? ?? 'UNREAD',
      messageId: data['message_id'] as String?,
      imageUrl: type == 'IMAGE' ? content : null,
      locationUrl: type == 'LOCATION' ? content : null,
    );
  }

  /// ─────────────────────────────────────────────────────────────
  /// 시간 순으로 정렬 (오름차순)
  List<ChatMessage> _sortMessagesByTime(List<ChatMessage> messages) {
    messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
    return messages;
  }

  /// ─────────────────────────────────────────────────────────────
  /// 재시도 로직 (UI 에서 호출)
  Future<bool> retryMessage(
    ChatMessage failedMessage,
    int chatRoomId,
    int senderId,
    String token,
  ) async {
    if (failedMessage.type == 'IMAGE' && failedMessage.imageFile != null) {
      final result = await uploadImage(
        failedMessage.imageFile!,
        chatRoomId,
        senderId,
        token,
      );
      return result != null;
    }
    // LOCATION, NORMAL 은 UI 레이어에서 STOMP 로직으로 처리
    return false;
  }

  /// ─────────────────────────────────────────────────────────────
  /// 로컬 저장 (메시지 + 커서)
  Future<void> _saveMessagesToLocal(int chatRoomId, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_messages_$chatRoomId';

    // ISO 문자열로 저장
    final jsonList = messages.map((msg) {
      return {
        'text': msg.text,
        'isSent': msg.isSent,
        'sentAt': msg.sentAt.toIso8601String(),
        'type': msg.type,
        'status': msg.status,
        'messageId': msg.messageId,
        'imageUrl': msg.imageUrl,
        'locationUrl': msg.locationUrl,
      };
    }).toList();

    await prefs.setString(key, json.encode(jsonList));
  }

  /// 로컬에 메시지 하나 추가
  Future<void> addMessageToLocal(int chatRoomId, ChatMessage message) async {
    final existing = await loadMessagesFromLocal(chatRoomId);
    existing.add(message);
    await _saveMessagesToLocal(chatRoomId, existing);
  }

  Future<List<ChatMessage>> loadMessagesFromLocal(int chatRoomId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chat_messages_$chatRoomId';
    final raw = prefs.getString(key);
    if (raw == null) return [];

    final List<dynamic> list = json.decode(raw);
    return list
        .map<ChatMessage>((e) {
          final m = e as Map<String, dynamic>;
          DateTime sentAt;
          try {
            sentAt = DateTime.parse(m['sentAt'] as String);
          } catch (_) {
            sentAt = DateTime.now();
          }
          return ChatMessage(
            text: m['text'] as String? ?? '',
            isSent: m['isSent'] as bool? ?? false,
            sentAt: sentAt,
            type: m['type'] as String? ?? 'NORMAL',
            status: m['status'] as String? ?? 'UNREAD',
            messageId: m['messageId'] as String?,
            imageUrl: m['imageUrl'] as String?,
            locationUrl: m['locationUrl'] as String?,
          );
        })
        .toList();
  }

  Future<void> _saveNextCursor(int chatRoomId, String cursor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_cursor_$chatRoomId', cursor);
  }

  Future<String?> getNextCursor(int chatRoomId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('chat_cursor_$chatRoomId');
  }

  Future<bool> clearLocalMessages(int chatRoomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_messages_$chatRoomId');
    await prefs.remove('chat_cursor_$chatRoomId');
    // API 차단 플래그 설정
    await prefs.setBool('block_api_chat_$chatRoomId', true);
    return true;
  }

  Future<bool> isApiBlocked(int chatRoomId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('block_api_chat_$chatRoomId') ?? false;
  }

  Future<bool> unblockApi(int chatRoomId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('block_api_chat_$chatRoomId');
    return true;
  }

  // 모든 채팅방의 메시지 삭제
  Future<bool> clearAllLocalMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();

      // 채팅 메시지 관련 키만 필터링
      final messageKeys =
          allKeys.where((key) => key.startsWith('chat_messages_')).toList();
      final cursorKeys =
          allKeys.where((key) => key.startsWith('chat_cursor_')).toList();

      // 각 키 삭제
      for (final key in messageKeys) {
        await prefs.remove(key);
      }

      for (final key in cursorKeys) {
        await prefs.remove(key);
      }

      print('모든 채팅방의 로컬 메시지가 삭제됨');
      return true;
    } catch (e) {
      print('모든 로컬 메시지 삭제 오류: $e');
      return false;
    }
  }

  // 의도적 연결 해제 상태를 저장하는 키
  String _getIntentionalDisconnectKey(int chatRoomId) =>
      'intentional_disconnect_$chatRoomId';

  // 의도적 연결 해제 표시
  Future<void> markIntentionalDisconnect(
    int chatRoomId,
    bool isIntentional,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getIntentionalDisconnectKey(chatRoomId);
      await prefs.setBool(key, isIntentional);
      print('✅ 채팅방($chatRoomId)의 의도적 연결 해제 상태: $isIntentional');
    } catch (e) {
      print('❌ 의도적 연결 해제 상태 저장 실패: $e');
    }
  }

  // 의도적 연결 해제 상태 확인
  Future<bool> isIntentionallyDisconnected(int chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getIntentionalDisconnectKey(chatRoomId);
      return prefs.getBool(key) ?? false;
    } catch (e) {
      print('❌ 의도적 연결 해제 상태 확인 실패: $e');
      return false;
    }
  }

  // 연결 시도 전에 확인할 메서드 (STOMP 클라이언트에서 사용)
  Future<bool> shouldAttemptReconnect(int chatRoomId) async {
    // 의도적으로 연결 해제된 경우 재연결 시도하지 않음
    final intentionalDisconnect = await isIntentionallyDisconnected(chatRoomId);
    return !intentionalDisconnect;
  }

  // 사용자 행동으로 연결 시작할 때 호출하는 메서드 개선
  Future<void> resetDisconnectState(int chatRoomId) async {
    print('🔄 [ChatService] 채팅방($chatRoomId)의 연결 상태 초기화 중...');
    await markIntentionalDisconnect(chatRoomId, false);
    print('✅ [ChatService] 채팅방($chatRoomId)의 연결 상태가 재설정되었습니다. 이제 연결이 가능합니다.');
  }

  // 채팅방 입장 시 호출할 메서드 추가
  Future<void> enterChatRoom(int chatRoomId) async {
    print('📲 [ChatService] 채팅방($chatRoomId) 입장 처리 중...');
    // API 호출 차단 해제
    await unblockApi(chatRoomId);
    // 연결 상태 초기화 (자동 연결 허용)
    await resetDisconnectState(chatRoomId);
    print('✅ [ChatService] 채팅방($chatRoomId) 입장 완료');
  }

  // 채팅방 퇴장 시 호출할 메서드 추가
  Future<void> leaveChatRoom(int chatRoomId) async {
    print('📴 [ChatService] 채팅방($chatRoomId) 퇴장 처리 중...');
    // 의도적 연결 해제 표시
    await markIntentionalDisconnect(chatRoomId, true);
    print('✅ [ChatService] 채팅방($chatRoomId) 퇴장 완료');
  }

  // 연결 상태 디버깅을 위한 헬퍼 메서드
  Future<Map<String, dynamic>> getConnectionState(int chatRoomId) async {
    final isIntentional = await isIntentionallyDisconnected(chatRoomId);
    final isApiBlocked = await this.isApiBlocked(chatRoomId);

    return {
      'chatRoomId': chatRoomId,
      'isIntentionallyDisconnected': isIntentional,
      'isApiBlocked': isApiBlocked,
      'shouldAttemptReconnect': !isIntentional,
    };
  }

  Future<Map<String, dynamic>?> getChatRoomDetail(
    int roomId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat-rooms/$roomId/detail'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        if (jsonData['success'] == true) {
          return jsonData['data'];
        }
      }
      return null;
    } catch (e) {
      print('채팅방 상세 정보 로드 오류: $e');
      return null;
    }
  }
}
