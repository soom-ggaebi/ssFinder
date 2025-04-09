import 'package:dio/dio.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:sumsumfinder/models/chat_message.dart';
import 'package:http/http.dart' as http;
import 'package:sumsumfinder/config/environment_config.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumsumfinder/utils/time_formatter.dart';

class ChatService {
  final Dio _dio = Dio();
  final String baseUrl = EnvironmentConfig.baseUrl;
  int? _currentUserId; // null로 초기화

  // 초기화 메서드 추가
  Future<void> initialize() async {
    // 사용자 ID 가져오기
    _currentUserId = await KakaoLoginService().getUserId();

    // 중복 메시지 체크 메서드 추가
    bool _isDuplicateMessage(
      ChatMessage newMsg,
      List<ChatMessage> existingMsgs,
    ) {
      return existingMsgs.any(
        (msg) =>
            msg.messageId == newMsg.messageId ||
            (msg.type == newMsg.type &&
                msg.text == newMsg.text &&
                msg.time == newMsg.time &&
                msg.isSent == newMsg.isSent),
      );
    }
  }

  // 이미지 업로드 메서드
  Future<ChatMessage?> uploadImage(
    File imageFile,
    int chatRoomId,
    int? senderId,
    String token,
  ) async {
    try {
      // senderId가 null인 경우 처리
      if (senderId == null) {
        print('이미지 업로드 실패: 유효한 사용자 ID가 없습니다.');
        return null;
      }

      // 현재 시간을 HH:MM 형식으로 가져오기
      final now = DateTime.now();
      final timeString = '${now.hour}:${now.minute.toString().padLeft(2, '0')}';

      // FormData 생성
      FormData formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      // 헤더 설정 - Bearer 접두사 추가
      _dio.options.headers = {'Authorization': 'Bearer $token'};

      print('업로드 URL: $baseUrl/api/chat-rooms/$chatRoomId/upload');
      print('토큰: Bearer $token');

      // API 요청
      Response response = await _dio.post(
        '$baseUrl/api/chat-rooms/$chatRoomId/upload',
        data: formData,
      );

      // 응답 디버깅 로그 추가
      print('이미지 업로드 응답: ${response.data}');

      // 응답 확인 및 처리
      if (response.statusCode == 200 && response.data['success'] == true) {
        // 서버에서 반환된 이미지 URL 추출
        String content = response.data['data']['content'];
        // <> 괄호 제거 (필요한 경우)
        if (content.startsWith('<') && content.endsWith('>')) {
          content = content.substring(1, content.length - 1);
        }

        print('파싱된 이미지 URL: $content');

        // 응답 데이터 로깅 추가
        print('이미지 업로드 응답: ${response.data}');

        // 새 ChatMessage 객체 생성 및 반환
        return ChatMessage(
          text: '',
          isSent: true,
          time: TimeFormatter.getCurrentTime(),
          imageUrl: content, // 괄호가 제거된 URL 사용
          type: 'IMAGE',
          status: 'SENT',
          // messageId 추가
          messageId: response.data['data']['message_id'],
        );
      } else {
        print('이미지 업로드 실패: ${response.data}');
        return null;
      }
    } catch (e) {
      print('이미지 업로드 중 오류 발생: $e');
      return null;
    }
  }

  // 메시지 로컬 저장을 위한 키 형식
  String _getMessageStorageKey(int chatRoomId) => 'chat_messages_$chatRoomId';
  String _getMessageCursorKey(int chatRoomId) => 'chat_cursor_$chatRoomId';

  // ChatService 클래스에서 수정할 부분:
  // 중복된 loadMessages 메서드 제거하고 하나만 유지

  // 2. 메시지 정렬 유틸리티 메서드 추가
  List<ChatMessage> _sortMessagesByTime(List<ChatMessage> messages) {
    // 메시지를 시간 기준으로 정렬 (최신 메시지가 앞에 오도록)
    messages.sort((a, b) {
      try {
        // 메시지 ID 기반 정렬 (더 높은 ID가 더 최신)
        if (a.messageId != null &&
            b.messageId != null &&
            !a.messageId!.startsWith('temp_') &&
            !b.messageId!.startsWith('temp_')) {
          int idA = int.tryParse(a.messageId!) ?? 0;
          int idB = int.tryParse(b.messageId!) ?? 0;
          return idB.compareTo(idA); // 내림차순
        }

        // 임시 ID는 항상 위로
        if (a.messageId != null && a.messageId!.startsWith('temp_')) return -1;
        if (b.messageId != null && b.messageId!.startsWith('temp_')) return 1;

        // 시간 기반 정렬 (더 최신이 앞에 오도록)
        if (a.time != b.time) {
          // 'HH:mm' 형식의 시간 비교
          List<int> aTimeParts = a.time.split(':').map(int.parse).toList();
          List<int> bTimeParts = b.time.split(':').map(int.parse).toList();

          // 시간 비교 (시, 분 순서)
          if (aTimeParts[0] != bTimeParts[0]) {
            return bTimeParts[0].compareTo(aTimeParts[0]); // 시 비교 (내림차순)
          } else {
            return bTimeParts[1].compareTo(aTimeParts[1]); // 분 비교 (내림차순)
          }
        }

        // 시간이 같으면 텍스트 비교
        return b.text.compareTo(a.text);
      } catch (e) {
        print('메시지 정렬 오류: $e');
        return 0;
      }
    });

    return messages;
  }

  // 3. loadMessages 메서드 개선
  // 3. loadMessages 메서드 개선
  Future<List<ChatMessage>> loadMessages(
    int chatRoomId, {
    int size = 20,
    String? cursor,
    int? userId,
    bool forceRefresh = false,
  }) async {
    try {
      // API 호출 차단 상태 확인
      final isBlocked = await isApiBlocked(chatRoomId);
      print('📝 [ChatService] 채팅방($chatRoomId)의 API 호출 차단 상태: $isBlocked');

      if (!forceRefresh && isBlocked) {
        print('📝 [ChatService] 채팅방($chatRoomId)의 API 호출이 차단되어 있습니다.');
        return [];
      }

      final token = await KakaoLoginService().getAccessToken();
      if (token == null) {
        print('📝 [ChatService] 토큰이 null입니다. 인증 문제가 있을 수 있습니다.');
        return [];
      }

      // 사용자 ID 가져오기
      int? currentUserId;
      if (userId != null) {
        currentUserId = userId;
      } else {
        // UserID가 없으면 초기화 시도
        if (_currentUserId == null) {
          _currentUserId = await KakaoLoginService().getUserId();
        }
        currentUserId = _currentUserId;
      }

      // ID가 여전히 null이면 메시지를 로드할 수 없음
      if (currentUserId == null) {
        print('📝 [ChatService] 유효한 사용자 ID를 가져올 수 없습니다. 메시지를 로드할 수 없습니다.');
        return [];
      }

      print('📝 [ChatService] 현재 사용자 ID: $currentUserId');

      // API 엔드포인트 구성
      String url = '$baseUrl/api/chat-rooms/$chatRoomId/messages?size=$size';
      if (cursor != null && cursor.isNotEmpty) {
        url += '&cursor=$cursor';
      }

      print('📝 [ChatService] 메시지 로드 URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📝 [ChatService] 서버 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        // 응답 본문 일부 출력 (너무 길면 잘라서)
        print(
          '📝 [ChatService] 응답 본문 일부: ${decodedBody.substring(0, decodedBody.length > 100 ? 100 : decodedBody.length)}...',
        );

        final data = json.decode(decodedBody);

        if (data['success'] == true) {
          final messagesData = data['data']['messages'] as List<dynamic>;
          print('📝 [ChatService] 서버에서 받은 메시지 수: ${messagesData.length}');

          final nextCursor = data['data']['nextCursor'] as String?;
          print('📝 [ChatService] 다음 커서: $nextCursor');

          // 다음 페이지를 위한 커서 저장
          if (nextCursor != null) {
            await _saveNextCursor(chatRoomId, nextCursor);
          }

          // 메시지 객체로 변환
          final messages =
              messagesData
                  .map(
                    (msg) => _convertToMessage(msg, chatRoomId, currentUserId),
                  )
                  .toList();

          // 메시지 정렬 (최신 메시지가 맨 앞으로)
          final sortedMessages = _sortMessagesByTime(messages);

          // 디버깅: 변환된 메시지의 일부 정보 출력
          if (sortedMessages.isNotEmpty) {
            print(
              '📝 [ChatService] 첫 번째 메시지 - 텍스트: ${sortedMessages[0].text}, ID: ${sortedMessages[0].messageId}, 타입: ${sortedMessages[0].type}',
            );
          }

          return sortedMessages;
        } else {
          print(
            '📝 [ChatService] 서버 응답이 success: false입니다. 오류 메시지: ${data['error']}',
          );
        }
      } else {
        print(
          '📝 [ChatService] 메시지 로드 실패: ${response.statusCode} - ${response.body}',
        );
      }

      return [];
    } catch (e) {
      print('📝 [ChatService] 메시지 로드 오류 (예외 발생): $e');
      return [];
    }
  }

  // ChatService 클래스에 추가
  Future<bool> retryMessage(
    ChatMessage failedMessage,
    int chatRoomId,
    int senderId,
    String token,
  ) async {
    try {
      // 메시지 타입에 따라 다른 재시도 로직 실행
      if (failedMessage.type == 'IMAGE' && failedMessage.imageFile != null) {
        // 이미지 메시지 재전송
        final result = await uploadImage(
          failedMessage.imageFile!,
          chatRoomId,
          senderId,
          token,
        );
        return result != null;
      } else if (failedMessage.type == 'LOCATION') {
        // 위치 메시지 재전송 로직
        // STOMP 클라이언트가 필요하므로 이 부분은 UI 레이어에서 처리해야 할 수 있음
        return false;
      } else {
        // 일반 텍스트 메시지 재전송 로직
        // STOMP 클라이언트가 필요하므로 이 부분은 UI 레이어에서 처리해야 할 수 있음
        return false;
      }
    } catch (e) {
      print('메시지 재시도 중 오류: $e');
      return false;
    }
  }

  // 로컬에 메시지 저장하는 public 메서드 추가 (private 메서드를 외부에서 호출할 수 있도록)
  Future<void> saveMessagesToLocal(
    int chatRoomId,
    List<ChatMessage> messages,
  ) async {
    await _saveMessagesToLocal(chatRoomId, messages);
  }

  // ChatService의 _convertToMessage 메서드 재확인
  ChatMessage _convertToMessage(
    Map<String, dynamic> data,
    int chatRoomId,
    int? currentUserId, // null 허용으로 변경
  ) {
    final int senderId = data['sender_id'] ?? -1;

    // 현재 사용자 ID가 null인 경우 처리
    final bool isSent = currentUserId != null && senderId == currentUserId;

    print(
      '메시지 변환: messageId=${data['message_id']}, senderId=$senderId, currentUserId=$currentUserId, isSent=${senderId == currentUserId}',
    );

    return ChatMessage(
      text: data['content'] ?? '',
      isSent: isSent, // 발신자 ID와 현재 사용자 ID 비교 (null 체크 포함)
      time: _formatTimeFromIso(data['sent_at'] ?? ''),
      type: data['type'] ?? 'NORMAL',
      status: data['status'] ?? 'UNREAD',
      messageId: data['message_id'],
    );
  }

  // ISO 형식 시간을 UI 표시용으로 변환
  String _formatTimeFromIso(String isoTime) {
    try {
      final dateTime = DateTime.parse(isoTime);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  // 로컬에 메시지 저장
  Future<void> _saveMessagesToLocal(
    int chatRoomId,
    List<ChatMessage> messages,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getMessageStorageKey(chatRoomId);

      // 메시지를 JSON으로 변환
      final List<Map<String, dynamic>> jsonList =
          messages
              .map(
                (msg) => {
                  'text': msg.text,
                  'isSent': msg.isSent,
                  'time': msg.time,
                  'type': msg.type,
                  'status': msg.status,
                  'messageId': msg.messageId,
                  'imageUrl': msg.imageUrl,
                  'locationUrl': msg.locationUrl,
                },
              )
              .toList();

      // JSON을 문자열로 변환하여 저장
      final String encodedData = json.encode(jsonList);
      await prefs.setString(key, encodedData);

      print('메시지 ${messages.length}개가 로컬에 저장됨');
    } catch (e) {
      print('메시지 로컬 저장 오류: $e');
    }
  }

  // 다음 페이지 조회를 위한 커서 저장
  Future<void> _saveNextCursor(int chatRoomId, String cursor) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getMessageCursorKey(chatRoomId);
      await prefs.setString(key, cursor);
    } catch (e) {
      print('커서 저장 오류: $e');
    }
  }

  // 저장된 커서 가져오기
  Future<String?> getNextCursor(int chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getMessageCursorKey(chatRoomId);
      return prefs.getString(key);
    } catch (e) {
      print('커서 로드 오류: $e');
      return null;
    }
  }

  // 로컬에서 메시지 불러오기
  Future<List<ChatMessage>> loadMessagesFromLocal(int chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getMessageStorageKey(chatRoomId);

      final String? encodedData = prefs.getString(key);
      if (encodedData == null) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(encodedData);

      return jsonList
          .map(
            (jsonMsg) => ChatMessage(
              text: jsonMsg['text'] ?? '',
              isSent: jsonMsg['isSent'] ?? false,
              time: jsonMsg['time'] ?? '',
              type: jsonMsg['type'] ?? 'NORMAL',
              status: jsonMsg['status'] ?? 'UNREAD',
              messageId: jsonMsg['messageId'],
              imageUrl: jsonMsg['imageUrl'],
              locationUrl: jsonMsg['locationUrl'],
            ),
          )
          .toList();
    } catch (e) {
      print('로컬 메시지 로드 오류: $e');
      return [];
    }
  }

  // 새 메시지를 로컬에 추가
  Future<void> addMessageToLocal(int roomId, ChatMessage message) async {
    try {
      // 기존 메시지 가져오기
      final messages = await loadMessagesFromLocal(roomId);

      // 새 메시지 추가
      messages.add(message);

      // 다시 저장
      await _saveMessagesToLocal(roomId, messages);

      print('✅ 로컬에 메시지 저장 성공');
    } catch (e) {
      print('❌ 로컬에 메시지 저장 실패: $e');
      throw Exception('메시지 로컬 저장 실패: $e');
    }
  }

  // 특정 채팅방의 메시지 삭제
  Future<bool> clearLocalMessages(int chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _getMessageStorageKey(chatRoomId);
      await prefs.remove(key);

      // 커서도 함께 삭제
      final cursorKey = _getMessageCursorKey(chatRoomId);
      await prefs.remove(cursorKey);

      // 로컬 메시지 삭제 후 API 호출 방지를 위한 플래그 설정
      final blockApiKey = 'block_api_chat_$chatRoomId';
      await prefs.setBool(blockApiKey, true);

      print('채팅방($chatRoomId)의 모든 로컬 메시지가 삭제됨');
      return true;
    } catch (e) {
      print('로컬 메시지 삭제 오류: $e');
      return false;
    }
  }

  // API 호출 차단 상태 확인 메서드 추가
  Future<bool> isApiBlocked(int chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockApiKey = 'block_api_chat_$chatRoomId';
      return prefs.getBool(blockApiKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // API 호출 차단 상태 해제 메서드 추가
  Future<bool> unblockApi(int chatRoomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final blockApiKey = 'block_api_chat_$chatRoomId';
      await prefs.remove(blockApiKey);
      return true;
    } catch (e) {
      return false;
    }
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

  Future<Map<String, dynamic>?> getChatRoomDetail(
    int roomId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat-rooms/$roomId/detail'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8', // UTF-8 명시
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // UTF-8 디코딩 명시적으로 처리
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
