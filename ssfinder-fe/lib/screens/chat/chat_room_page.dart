import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async'; // Timer 클래스를 위한 임포트
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sumsumfinder/models/chat_message.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:sumsumfinder/config/environment_config.dart';
import 'package:sumsumfinder/widgets/chat/product_info.dart';
import 'package:sumsumfinder/widgets/chat/info_banner.dart';
import 'package:sumsumfinder/widgets/chat/date_divider.dart';
import 'package:sumsumfinder/widgets/chat/chat_input_field.dart';
import 'package:sumsumfinder/widgets/chat/chat_message_bubble.dart';
import 'package:sumsumfinder/utils/time_formatter.dart';
import 'package:sumsumfinder/widgets/chat/option_popups/add.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/widgets/selects/location_select.dart';
import 'package:sumsumfinder/services/chat_service.dart'; // ChatService 추가
import 'package:permission_handler/permission_handler.dart'; // 권한 처리 패키지 추가
import 'dart:math' show min;

class ChatPage extends StatefulWidget {
  final int roomId;
  final String otherUserName;
  final String myName;

  const ChatPage({
    Key? key,
    required this.roomId,
    required this.otherUserName,
    required this.myName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

// 구독 변수를 함수 타입으로 선언
typedef UnsubscribeFn =
    void Function({Map<String, String>? unsubscribeHeaders});

class _ChatPageState extends State<ChatPage> {
  final KakaoLoginService _loginService = KakaoLoginService();
  final ChatService _chatService = ChatService(); // ChatService 인스턴스 추가
  String? _currentToken;
  // 구독 함수를 저장할 변수
  UnsubscribeFn? chatRoomUnsubscribeFn; // 채팅방 구독 함수
  UnsubscribeFn? errorUnsubscribeFn; // 에러 구독 함수
  UnsubscribeFn? readStatusUnsubscribeFn; // 읽음 상태 구독 함수

  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  int? currentUserId; // 현재 사용자 ID (실제 ID로 변경 필요)

  // STOMP 웹소켓 관련 변수
  late StompClient stompClient;
  bool _isStompClientInitialized = false; // 초기화 여부를 추적하는 플래그 추가
  bool isConnected = false;
  int reconnectAttempts = 0;
  // 구독 ID를 저장할 변수들 (구독 취소를 위해)
  String? chatRoomSubscriptionId;
  String? errorSubscriptionId;

  // 디버깅을 위한 로그
  final List<String> logs = [];
  bool showDebugPanel = false;

  bool _isLoading = false;
  bool _hasMoreMessages = true;
  String? _nextCursor;
  final int _pageSize = 20;
  bool _disposed = false;

  // 7. 초기화 메서드 개선 - 자동 재연결 설정 추가
  @override
  void initState() {
    super.initState();
    print('ChatPage 초기화');

    // API 호출 차단 상태 해제
    _chatService.unblockApi(widget.roomId).then((_) {
      print('API 호출 차단 상태 해제됨');
    });

    // 권한 확인
    _checkPermissions();

    // 사용자 정보 초기화 후 다른 작업 수행
    _initializeUserData().then((_) {
      // 로그 추가
      print('사용자 초기화 완료 - ID: $currentUserId');

      // 메시지 로드 및 채팅방 상세 정보 로드
      if (currentUserId != null) {
        _loadInitialMessages();
        _loadChatRoomDetail();
        setupAutoReconnect();
      } else {
        print('사용자 ID가 초기화되지 않았습니다. 메시지를 로드할 수 없습니다.');
      }
    });
  }

  // 사용자 데이터 초기화를 위한 새 메서드
  Future<void> _initializeUserData() async {
    if (_disposed || currentUserId != null) return; // 이미 초기화된 경우 건너뛰기

    // 1. 토큰 가져오기
    await _fetchLatestToken();
    if (_disposed) return;

    // 2. 사용자 프로필 가져오기
    try {
      final userProfile = await _loginService.getUserProfile();
      if (_disposed || userProfile == null) return;

      // ID 값 추출 및 변환
      final userId = userProfile['id'];
      print('원본 사용자 ID: $userId (${userId.runtimeType})');

      int? userIdInt;
      if (userId is int) {
        userIdInt = userId;
      } else if (userId is String) {
        userIdInt = int.tryParse(userId);
      }

      if (userIdInt != null) {
        setState(() {
          currentUserId = userIdInt;
          print('사용자 ID 설정 완료: $currentUserId');
        });

        // STOMP 클라이언트 초기화
        if (_currentToken != null && mounted) {
          initStompClient();
        }
      } else {
        print('사용자 ID를 유효한 정수로 변환할 수 없습니다.');
      }
    } catch (e) {
      print('사용자 프로필 가져오기 오류: $e');
    }
  }

  // 사용자 닉네임 초기화 메서드 수정
  Future<void> _initializeUserName() async {
    try {
      final userProfile = await _loginService.getUserProfile();
      if (userProfile != null) {
        // 사용자 ID 타입 확인 및 변환
        final userId = userProfile['id'];
        int userIdInt;

        if (userId is int) {
          userIdInt = userId;
        } else if (userId is String) {
          userIdInt = int.tryParse(userId) ?? 0;
        } else {
          userIdInt = 0;
        }

        setState(() {
          currentUserId = userIdInt;
          print('현재 사용자 ID 설정: $currentUserId');
        });
      }
    } catch (e) {
      print('사용자 프로필 로드 오류: $e');
    }
  }

  // 6. 메시지 로드 시 중복 제거 및 정렬 개선
  Future<void> _loadMessagesFromApi({bool isLoadMore = false}) async {
    if (_disposed) return;
    if (currentUserId == null) {
      print('사용자 ID가 초기화되지 않았습니다. 메시지를 로드할 수 없습니다.');
      return;
    }

    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final cursor = isLoadMore ? _nextCursor : null;
      print(
        '메시지 로딩 - roomId: ${widget.roomId}, 커서: $cursor, 페이지 크기: $_pageSize',
      );

      final messages = await _chatService.loadMessages(
        widget.roomId,
        size: _pageSize,
        cursor: cursor,
        userId: currentUserId, // null이 아닌 값을 전달
        forceRefresh: true, // 항상 API에서 새로 데이터 가져오기
      );

      print('로드된 메시지 수: ${messages.length}');

      if (_disposed) return;

      setState(() {
        if (isLoadMore) {
          // 중복 메시지 방지를 위해 ID 기반으로 확인 후 추가
          for (final newMsg in messages) {
            if (newMsg.messageId != null &&
                !_messages.any((msg) => msg.messageId == newMsg.messageId)) {
              _messages.add(newMsg);
            }
          }
        } else {
          // 기존 메시지 대체
          _messages = messages;
        }

        // 메시지 정렬 - 항상 최신 메시지가 맨 위에 오도록
        _sortMessages();

        _isLoading = false;
      });

      // 페이지네이션 정보 업데이트
      _nextCursor = await _chatService.getNextCursor(widget.roomId);
      // 비어있는 커서인 경우 더 이상 메시지가 없다고 처리
      _hasMoreMessages = _nextCursor != null && _nextCursor!.isNotEmpty;

      print('다음 커서: $_nextCursor, 추가 메시지 여부: $_hasMoreMessages');
      print('현재 메시지 개수: ${_messages.length}');
    } catch (e) {
      print('메시지 로딩 중 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 더 많은 메시지 로드 (스크롤시 호출) 메서드 추가
  void _loadMoreMessages() {
    if (!_isLoading &&
        _hasMoreMessages &&
        _nextCursor != null &&
        _nextCursor!.isNotEmpty) {
      setState(() {
        _isLoading = true; // 로딩 중 상태로 변경하여 중복 로드 방지
      });
      _loadMessagesFromApi(isLoadMore: true).then((_) {
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  // 최초 메시지 로드 처리
  Future<void> _loadInitialMessages() async {
    if (_disposed) return;

    setState(() {
      _isLoading = true;
      _messages = [];
      _hasMoreMessages = true;
      _nextCursor = null;
    });

    try {
      // API 호출 차단 상태 해제 확인
      await _chatService.unblockApi(widget.roomId);

      // 서버에서 메시지 가져오기
      await _loadMessagesFromApi();

      if (_disposed) return;

      // 연결 상태이면 읽지 않은 메시지 처리
      if (isConnected) {
        _processUnreadMessages();
      }

      setState(() {
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      print('메시지 로드 중 오류: $e');

      if (_disposed) return;

      setState(() {
        _isLoading = false;
      });
    }
  }

  // 1. _ChatPageState 클래스 내 메시지 처리 및 정렬 개선

  // 메시지 처리를 위한 유틸리티 메서드 추가
  void _addOrUpdateMessage(ChatMessage message) {
    if (!mounted) return;

    setState(() {
      // messageId로 기존 메시지 찾기
      int existingIndex = -1;
      if (message.messageId != null) {
        existingIndex = _messages.indexWhere(
          (msg) => msg.messageId == message.messageId,
        );
      }

      // 임시 메시지 업데이트 (본인이 보낸 메시지인 경우)
      if (existingIndex == -1 && message.isSent) {
        existingIndex = _messages.indexWhere(
          (msg) =>
              msg.messageId != null &&
              msg.messageId!.startsWith('temp_') &&
              msg.type == message.type &&
              msg.text == message.text,
        );
      }

      if (existingIndex != -1) {
        // 기존 메시지 업데이트
        _messages[existingIndex] = message;
      } else {
        // 새 메시지 추가 - 항상 최신 메시지는 맨 앞에 추가 (일관성)
        _messages.insert(0, message);
      }

      // 메시지 정렬 (최신 메시지가 맨 위에 오도록)
      _sortMessages();
    });
  }

  // 메시지 정렬 함수 (최신 메시지가 맨 위에 오도록 내림차순 정렬)
  void _sortMessages() {
    _messages.sort((a, b) {
      try {
        // 메시지 ID가 있으면 숫자 기반 정렬 (더 최신 메시지가 더 큰 ID 값)
        if (a.messageId != null &&
            b.messageId != null &&
            !a.messageId!.startsWith('temp_') &&
            !b.messageId!.startsWith('temp_')) {
          // 문자열 ID를 숫자로 변환 시도
          int idA = int.tryParse(a.messageId!) ?? 0;
          int idB = int.tryParse(b.messageId!) ?? 0;
          return idB.compareTo(idA); // 내림차순 (최신이 위로)
        }

        // 임시 ID는 항상 위로
        if (a.messageId != null && a.messageId!.startsWith('temp_')) return -1;
        if (b.messageId != null && b.messageId!.startsWith('temp_')) return 1;

        // 시간 기반 정렬 (보조 정렬 기준)
        return b.time.compareTo(a.time); // 내림차순 (최신이 위로)
      } catch (e) {
        print('메시지 정렬 오류: $e');
        return 0;
      }
    });
  }

  // 메시지 병합 및 중복 제거 메서드 추가
  List<ChatMessage> _mergeMessages(
    List<ChatMessage> apiMessages,
    List<ChatMessage> localMessages,
  ) {
    // 모든 메시지를 합친 후, messageId 기준으로 중복 제거
    final allMessages = [...apiMessages];

    for (final localMsg in localMessages) {
      if (localMsg.messageId != null) {
        // messageId가 있는 경우 중복 체크
        if (!allMessages.any((msg) => msg.messageId == localMsg.messageId)) {
          allMessages.add(localMsg);
        }
      } else {
        // messageId가 없는 경우 시간과 내용으로 중복 체크
        bool isDuplicate = allMessages.any(
          (msg) =>
              msg.time == localMsg.time &&
              msg.text == localMsg.text &&
              msg.type == localMsg.type,
        );

        if (!isDuplicate) {
          allMessages.add(localMsg);
        }
      }
    }

    // 최신 메시지가 위로 오도록 정렬
    allMessages.sort((a, b) {
      // 시간 기반 정렬 로직 추가 (필요시)
      return 0; // 임시로 정렬 없이 유지
    });

    return allMessages;
  }

  // 모든 메시지 초기화 및 API 호출 차단
  Future<void> _clearMessages() async {
    if (_disposed) return;

    await _chatService.clearLocalMessages(widget.roomId);
    if (_disposed) return;

    setState(() {
      _messages = [];
      _nextCursor = null;
      _hasMoreMessages = false;
    });
    addLog('모든 채팅 메시지가 삭제됨 및 API 호출 차단됨');
  }

  // 권한 확인 메서드 추가
  Future<void> _checkPermissions() async {
    if (_disposed) return;

    Map<Permission, PermissionStatus> statuses =
        await [Permission.camera, Permission.storage].request();
    if (_disposed) return;

    addLog('카메라 권한: ${statuses[Permission.camera]}');
    addLog('저장소 권한: ${statuses[Permission.storage]}');
  }

  Future<void> _fetchLatestToken() async {
    if (_disposed) return;

    final token = await _loginService.getAccessToken();
    if (_disposed) return;

    setState(() {
      _currentToken = token;
    });

    if (_currentToken != null) {
      initStompClient();
    } else {
      addLog('토큰이 없습니다. 로그인이 필요합니다.');
    }
  }

  @override
  void dispose() {
    // 모든 비동기 작업 취소를 위한 플래그 설정
    _disposed = true;

    // 컨트롤러 정리
    _textController.dispose();
    _scrollController.dispose();

    // WebSocket 정리
    try {
      if (stompClient.connected) {
        // 구독 취소 시도 (null 체크 포함)
        if (chatRoomUnsubscribeFn != null) {
          chatRoomUnsubscribeFn!();
          chatRoomUnsubscribeFn = null;
        }

        if (errorUnsubscribeFn != null) {
          errorUnsubscribeFn!();
          errorUnsubscribeFn = null;
        }

        if (readStatusUnsubscribeFn != null) {
          readStatusUnsubscribeFn!();
          readStatusUnsubscribeFn = null;
        }

        // 명시적으로 연결 종료
        stompClient.deactivate();
        // stompClient = null; // 제거: late 변수에 null 할당할 수 없음
      }
    } catch (e) {
      print('dispose 중 오류: $e');
    }

    super.dispose();
  }

  // 로그 추가 함수
  void addLog(String log) {
    print('📝 [ChatPage] $log'); // 항상 로그는 출력

    if (!mounted) return; // mounted 상태 확인 추가

    setState(() {
      logs.add('${DateTime.now().toString().substring(11, 19)}: $log');
      if (logs.length > 100) logs.removeAt(0);
    });
  }

  bool _isInitializingClient = false;

  // STOMP 클라이언트 초기화
  void initStompClient() async {
    // 이미 초기화되고 연결된 상태면 건너뛰기
    if (_isStompClientInitialized && stompClient.connected) {
      print('🟢 STOMP 클라이언트가 이미 연결되어 있습니다.');
      return;
    }
    _isInitializingClient = true;

    try {
      // 기존 연결이 있으면 먼저 정리
      if (_isStompClientInitialized && stompClient.connected) {
        stompClient.deactivate();
      }
    } catch (e) {
      print('💥 STOMP 클라이언트 정리 중 오류: $e');
    }

    try {
      // 토큰 갱신 확인
      await _loginService.ensureAuthenticated();

      // 최신 토큰 가져오기
      _currentToken = await _loginService.getAccessToken();

      if (_currentToken == null) {
        print('🚫 토큰이 null입니다. STOMP 클라이언트 초기화를 중단합니다.');
        return;
      }

      // 사용자 ID 확인
      if (currentUserId == null) {
        print('🚫 사용자 ID가 null입니다. 사용자 정보 초기화를 시도합니다.');
        await _initializeUserData();
        if (currentUserId == null) {
          print('🚫 사용자 ID 초기화 실패. STOMP 클라이언트 초기화를 중단합니다.');
          return;
        }
      }

      print('🔌 STOMP 클라이언트 초기화 시작');
      print('🔑 최신 토큰으로 갱신됨: $_currentToken');
      print('🏠 채팅방 ID: ${widget.roomId}');

      // WebSocket 서버 URL
      final String serverUrl = 'wss://ssfinder.site/app/';

      // STOMP 클라이언트 설정
      stompClient = StompClient(
        config: StompConfig(
          url: serverUrl,
          onConnect: (frame) {
            print('🟢 STOMP 연결 성공');
            print('📨 프레임 헤더: ${frame.headers}');
            print('📦 프레임 본문: ${frame.body}');

            if (mounted) onConnect(frame);
          },
          onDisconnect: (frame) {
            print('🔴 STOMP 연결 해제');
            if (mounted) onDisconnect(frame);
          },
          onWebSocketError: (error) {
            print('❌ WebSocket 오류: $error');
            if (mounted) onWebSocketError(error);
          },
          onStompError: (frame) {
            print('❗ STOMP 오류: ${frame.body}');
            if (mounted) onStompError(frame);
          },
          onDebugMessage: (String message) {
            print('🐞 디버그 메시지: $message');
          },
          stompConnectHeaders: {
            'accept-version': '1.0,1.1,1.2',
            'heart-beat': '5000,5000',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_currentToken',
            'chat_room_id': '${widget.roomId}',
          },
        ),
      );

      _isStompClientInitialized = true;
      print('🚀 STOMP 클라이언트 활성화');
      stompClient.activate();
    } catch (e) {
      print('💥 STOMP 클라이언트 초기화 중 심각한 오류: $e');
      addLog('STOMP 클라이언트 초기화 중 오류가 발생했습니다: $e');
    }
  }

  // 클래스 전역 플래그 추가
  bool _isSubscribingToReadStatus = false;
  bool _isSubscribingToChatRoom = false;
  bool _isSubscribingToErrors = false;

  // 연결 성공 후 구독 메서드 개선
  void onConnect(StompFrame frame) {
    addLog('연결 성공: ${frame.body}');
    addLog('연결 헤더: ${frame.headers}'); // 헤더 정보 로깅 추가

    if (!mounted) return;

    setState(() {
      isConnected = true;
    });

    // 연결이 완전히 활성화될 때까지 잠시 지연
    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted || !stompClient.connected) return;

      // 채팅방 구독 (중복 방지)
      if (!_isSubscribingToChatRoom) {
        _isSubscribingToChatRoom = true;
        subscribeToChatRoom();
      }

      // 에러 구독 (중복 방지)
      if (!_isSubscribingToErrors) {
        _isSubscribingToErrors = true;
        subscribeToErrors();
      }

      // 읽음 상태 구독 추가 (중복 방지)
      if (!_isSubscribingToReadStatus) {
        _isSubscribingToReadStatus = true;
        subscribeToReadStatus();
      }

      // 온라인 상태 알림 추가
      stompClient.send(
        destination: '/app/chat-room/${widget.roomId}/online',
        body: json.encode({
          "chat_room_id": widget.roomId,
          "user_id": currentUserId,
        }),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
        },
      );

      // 서버로 연결 확인 메시지 전송
      try {
        stompClient.send(
          destination: '/app/connect',
          body: json.encode({"chat_room_id": widget.roomId}),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_currentToken',
          },
        );

        // 1. 방에 접속했다는 신호 전송 (사용자 상태를 온라인으로 변경)
        stompClient.send(
          destination: '/app/connect',
          body: json.encode({
            "chat_room_id": widget.roomId,
            "user_id": currentUserId,
          }),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_currentToken',
          },
        );

        // 2. 읽지 않은 메시지 처리 (이미 있는 코드)
        _processUnreadMessages();

        addLog('연결 확인 메시지 전송 성공');
      } catch (e) {
        addLog('연결 확인 메시지 전송 실패: $e');
      }
    });
  }

  // 읽지 않은 메시지 처리 메서드 추가
  void _processUnreadMessages() {
    if (currentUserId == null || _messages.isEmpty) return;

    // 상대방이 보낸 읽지 않은 메시지 찾기
    final List<String> unreadMessageIds =
        _messages
            .where(
              (msg) =>
                  !msg.isSent &&
                  msg.status == 'UNREAD' &&
                  msg.messageId != null,
            )
            .map((msg) => msg.messageId!)
            .toList();

    // 읽지 않은 메시지가 있으면 읽음 상태 전송
    if (unreadMessageIds.isNotEmpty) {
      addLog('읽지 않은 메시지 ${unreadMessageIds.length}개 읽음 처리 시작');
      sendReadReceipt(unreadMessageIds);
    }
  }

  // 읽음 상태 전송 메서드 추가
  void sendReadReceipt(List<String> messageIds) {
    if (!isConnected || messageIds.isEmpty) return;

    final destination = '/pub/chat-room/${widget.roomId}/read';
    final readJson = jsonEncode({
      "chat_room_id": widget.roomId,
      "message_ids": messageIds,
    });

    stompClient.send(
      destination: destination,
      body: readJson,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_currentToken',
      },
    );
  }

  // 3. 읽음 상태 처리 개선
  void subscribeToReadStatus() {
    // 기존 구독 취소
    if (readStatusUnsubscribeFn != null) {
      try {
        readStatusUnsubscribeFn!();
        readStatusUnsubscribeFn = null;
      } catch (e) {
        print('읽음 상태 구독 취소 오류: $e');
      }
    }

    // 새 구독 생성
    final String topic = '/sub/chat-room/${widget.roomId}/read';
    readStatusUnsubscribeFn = stompClient.subscribe(
      destination: topic,
      callback: (StompFrame frame) {
        if (frame.body == null || frame.body!.isEmpty) return;

        addLog('읽음 상태 업데이트 수신: ${frame.body}');

        final jsonData = json.decode(frame.body!);

        // API 명세서에 따른 파라미터
        final int userId = jsonData['user_id'];
        final List<String> messageIds = List<String>.from(
          jsonData['message_ids'],
        );
        final int chatRoomId = jsonData['chat_room_id'];

        // 상대방의 메시지 상태 업데이트인지 확인
        if (userId != currentUserId) {
          addLog('상대방(ID: $userId)이 메시지 ${messageIds.length}개를 읽음');

          // 주요 조건 확인
          if (chatRoomId != widget.roomId) return; // 현재 채팅방 확인
          if (userId == currentUserId) return; // 본인의 메시지 제외

          // 읽음 상태 업데이트
          setState(() {
            // 해당 ID의 메시지 상태 업데이트
            for (int i = 0; i < _messages.length; i++) {
              if (_messages[i].isSent &&
                  messageIds.contains(_messages[i].messageId)) {
                _messages[i] = ChatMessage(
                  text: _messages[i].text,
                  isSent: _messages[i].isSent,
                  time: _messages[i].time,
                  type: _messages[i].type,
                  status: 'READ',
                  messageId: _messages[i].messageId,
                  imageUrl: _messages[i].imageUrl,
                  locationUrl: _messages[i].locationUrl,
                );
              }
            }
          });
        }
      },
    );
    addLog('읽음 상태 구독 완료: $topic');
  }

  // 채팅방 구독 메서드 개선
  void subscribeToChatRoom() {
    try {
      // 연결 상태 재확인
      if (!stompClient.connected) {
        addLog('⚠️ 채팅방 구독 시도 실패: STOMP 클라이언트가 연결되지 않았습니다.');
        // 플래그 초기화 및 자동 재시도 예약
        _isSubscribingToChatRoom = false;
        Future.delayed(Duration(seconds: 2), () {
          if (mounted && isConnected && !_isSubscribingToChatRoom) {
            _isSubscribingToChatRoom = true;
            subscribeToChatRoom();
          }
        });
        return;
      }
      // 기존 구독 취소
      if (chatRoomUnsubscribeFn != null) {
        try {
          chatRoomUnsubscribeFn!();
          chatRoomUnsubscribeFn = null;
        } catch (e) {
          print('채팅방 구독 취소 오류: $e');
        }
      }

      // 새 구독 생성
      final String topic = '/sub/chat-room/${widget.roomId}';
      addLog('📝 채팅방 구독 시도: $topic');

      chatRoomUnsubscribeFn = stompClient.subscribe(
        destination: topic,
        callback: (StompFrame frame) {
          try {
            if (frame.body == null || frame.body!.isEmpty) {
              print('⚠️ 빈 메시지 프레임을 받았습니다.');
              return;
            }

            // 메시지 파싱 시도
            Map<String, dynamic> jsonData;
            try {
              jsonData = json.decode(frame.body!);
            } catch (e) {
              print('⚠️ JSON 파싱 오류: $e');
              print('⚠️ 원본 데이터: ${frame.body}');
              return;
            }

            // 수신된 메시지 로그 추가
            addLog('메시지 수신: ${frame.body}');

            // 필수 필드 검증
            final senderId = jsonData['sender_id'];
            if (senderId == null) {
              print('⚠️ 메시지에 sender_id가 없습니다.');
            }

            final ChatMessage message = ChatMessage(
              text: jsonData['content'] ?? '',
              isSent: senderId == currentUserId,
              time: TimeFormatter.getCurrentTime(),
              type: jsonData['type'] ?? 'NORMAL',
              status: jsonData['status'] ?? 'UNREAD',
              messageId: jsonData['message_id'],
            );

            if (mounted) {
              _addOrUpdateMessage(message);

              // 상대방 메시지인 경우 자동 읽음 처리
              if (!message.isSent && message.messageId != null) {
                sendReadReceipt([message.messageId!]);
              }
            }
          } catch (e) {
            print('⚠️ 메시지 처리 중 오류: $e');
            if (frame.body != null) {
              print('⚠️ 문제가 발생한 메시지: ${frame.body}');
            }
          }
        },
      );

      // 구독 확인 로그 추가
      addLog('채팅방 구독 완료: $topic');
    } catch (e) {
      _isSubscribingToChatRoom = false; // 오류 시 플래그 초기화
      addLog('채팅방 구독 중 오류: $e');
      // 오류 발생 시 잠시 후 재시도
      Future.delayed(Duration(seconds: 2), () {
        if (mounted && isConnected && !_isSubscribingToChatRoom) {
          _isSubscribingToChatRoom = true;
          subscribeToChatRoom();
        }
      });
    }
  }

  void subscribeToErrors() {
    final String topic = '/user/queue/errors';
    addLog('에러 구독 시도: $topic');

    try {
      // 반환된 함수를 저장
      errorUnsubscribeFn = stompClient.subscribe(
        destination: topic,
        callback: (StompFrame frame) {
          addLog('에러 수신: ${frame.body}');

          if (!mounted) return;

          // 사용자에게 오류 알림
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('서버 오류: ${frame.body}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );

      addLog('에러 구독 성공');
    } catch (e) {
      addLog('에러 구독 오류: $e');
    }
  }

  // 연결 해제 시 호출
  void onDisconnect(StompFrame frame) {
    addLog('연결 종료: ${frame.body}');

    if (!mounted) return;

    setState(() {
      isConnected = false;
      _isSubscribingToChatRoom = false;
      _isSubscribingToReadStatus = false;
      _isSubscribingToErrors = false;
    });
  }

  // WebSocket 오류 발생 시 호출
  void onWebSocketError(dynamic error) {
    addLog('WebSocket 오류: $error');

    if (!mounted) return; // mounted 상태 확인 추가

    setState(() {
      isConnected = false;
    });

    if (mounted) {
      // ScaffoldMessenger 사용 전 확인
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('연결 오류가 발생했습니다: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void onStompError(StompFrame frame) {
    addLog('STOMP 오류: ${frame.body}');

    if (!mounted) return;

    // 토큰 관련 오류인지 확인
    if (frame.body != null &&
        (frame.body!.toLowerCase().contains('token') ||
            frame.body!.toLowerCase().contains('auth') ||
            frame.body!.toLowerCase().contains('unauthorized'))) {
      addLog('토큰 관련 오류 감지. 토큰 갱신 후 재연결 시도');
      _refreshTokenAndReconnect();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('STOMP 프로토콜 오류가 발생했습니다'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _refreshTokenAndReconnect() async {
    if (!mounted) return;

    addLog('토큰 갱신 및 재연결 시도');

    try {
      // 토큰 갱신
      final refreshed = await _loginService.refreshAccessToken();
      if (refreshed) {
        addLog('토큰 갱신 성공, 웹소켓 재연결 시도');
        await reconnect();
      } else {
        addLog('토큰 갱신 실패');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증 오류가 발생했습니다. 다시 로그인해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      addLog('토큰 갱신 및 재연결 중 오류: $e');
    }
  }

  // 5. 자동 재연결 메커니즘 개선
  Future<void> setupAutoReconnect() async {
    // 주기적으로 연결 상태 확인
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }

      if (!isConnected && reconnectAttempts < 5) {
        reconnectAttempts++;
        addLog('자동 재연결 시도 ($reconnectAttempts/5)...');
        reconnect();
      } else if (isConnected) {
        reconnectAttempts = 0; // 연결 성공 시 카운터 초기화
      }
    });
  }

  // 재연결 메서드 개선
  Future<void> reconnect() async {
    if (_disposed) return;

    addLog('재연결 시도');
    // 이미 연결된 상태면 재연결 필요 없음
    if (isConnected) {
      print('🟢 이미 연결되어 있습니다. 재연결 불필요.');
      return;
    }

    // 재연결 중인 상태 표시
    setState(() {
      isConnected = false;
    });

    await _fetchLatestToken();
    if (_disposed) return;

    try {
      // 현재 클라이언트가 활성화된 경우 비활성화
      if (_isStompClientInitialized && stompClient.connected) {
        // 구독 취소 (구독 함수 호출 방식으로)
        if (chatRoomUnsubscribeFn != null) {
          try {
            chatRoomUnsubscribeFn!();
            chatRoomUnsubscribeFn = null;
          } catch (e) {
            addLog('채팅방 구독 취소 중 오류: $e');
          }
        }

        if (errorUnsubscribeFn != null) {
          try {
            errorUnsubscribeFn!();
            errorUnsubscribeFn = null;
          } catch (e) {
            addLog('에러 구독 취소 중 오류: $e');
          }
        }

        // 읽음 상태 구독 취소 추가
        if (readStatusUnsubscribeFn != null) {
          try {
            readStatusUnsubscribeFn!();
            readStatusUnsubscribeFn = null;
          } catch (e) {
            addLog('읽음 상태 구독 취소 중 오류: $e');
          }
        }

        // 연결 종료
        stompClient.deactivate();
      }
    } catch (e) {
      addLog('연결 종료 중 오류: $e');
    }

    // 새로운 연결 초기화
    initStompClient();

    // 연결 실패 시 UI에 알림
    Future.delayed(const Duration(seconds: 5), () {
      if (!isConnected && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('서버 연결에 문제가 있습니다. 다시 시도해 주세요.'),
            action: SnackBarAction(label: '재시도', onPressed: reconnect),
          ),
        );
      }
    });
  }

  // 4. 메시지 전송 개선
  void sendMessage(String text) {
    if (!isConnected) return;

    final destination = '/pub/chat-room/${widget.roomId}';
    final messageJson = jsonEncode({
      "type": "NORMAL",
      "content": text,
      "chat_room_id": widget.roomId,
      "sender_id": currentUserId,
    });

    // 로그 추가
    addLog('메시지 전송 시도: $messageJson');

    stompClient.send(
      destination: destination,
      body: messageJson,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_currentToken',
        'chat_room_id': '${widget.roomId}',
      },
    );
    // 전송 확인 로그
    addLog('메시지 전송 완료');
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();

    if (!mounted) return;

    if (!isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결 오류. 다시 시도해주세요.')));
      return;
    }

    // 임시 메시지 ID 생성
    String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // 임시 메시지 생성
    final tempMessage = ChatMessage(
      text: text,
      isSent: true,
      time: TimeFormatter.getCurrentTime(),
      type: 'NORMAL',
      status: 'SENDING',
      messageId: tempId,
    );

    // UI에 즉시 표시
    setState(() {
      _messages.insert(0, tempMessage);
      _sortMessages();
    });

    // 스크롤 조정
    _scrollToBottom();

    // 웹소켓으로 메시지 전송
    sendMessage(text);
  }

  void _scrollToBottom() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendImageMessage(File imageFile) async {
    if (_disposed) return;

    try {
      final token = await _loginService.getAccessToken();
      if (_disposed) return;

      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
        return;
      }

      // 현재 사용자 ID 확인
      if (currentUserId == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사용자 정보를 가져올 수 없습니다')));
        return;
      }

      // 임시 메시지 생성 (UI 즉시 업데이트)
      final tempMessage = ChatMessage(
        text: '',
        isSent: true,
        time: TimeFormatter.getCurrentTime(),
        type: 'IMAGE',
        imageFile: imageFile, // 로컬 파일 참조
        status: 'SENDING', // 전송 중 상태
      );

      // 여기서 insert(0)을 사용하여 최상단에 추가
      setState(() {
        _messages.insert(0, tempMessage);
      });
      _scrollToBottom();

      // 로딩 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 이미지 크기 로깅 (디버깅용)
      final fileSize = await imageFile.length();
      addLog('이미지 전송 시작: ${imageFile.path}, 파일 크기: $fileSize 바이트');

      // ChatService의 uploadImage 메서드 사용
      final result = await _chatService.uploadImage(
        imageFile,
        widget.roomId,
        currentUserId!, // null이 아님을 확신 (위에서 체크했으니)
        token,
      );
      // 로딩 닫기
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (result != null) {
        setState(() {
          // 임시 메시지 찾기
          final index = _messages.indexOf(tempMessage);
          if (index != -1) {
            // 임시 메시지를 서버에서 받은 결과로 업데이트
            _messages[index] = result;
            addLog('이미지 메시지 업데이트 완료: ${result.imageUrl}');
          } else {
            // 찾지 못했다면 추가
            _messages.insert(0, result);
            addLog('이미지 메시지 추가 완료: ${result.imageUrl}');
          }
        });

        // 로컬에도 저장
        _chatService.addMessageToLocal(widget.roomId, result);

        addLog('이미지 전송 성공: ${result.imageUrl}');
      } else {
        // 실패 시 임시 메시지 상태 업데이트
        setState(() {
          final index = _messages.indexOf(tempMessage);
          if (index != -1) {
            _messages[index].status = 'FAILED';
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지 전송 실패')));
      }
    } catch (e) {
      if (_disposed) return;
      // 로딩 닫기
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 전송 중 오류가 발생했습니다: $e')));
      addLog('이미지 전송 오류: $e');
    }
  }

  // 위치 메시지 전송 메서드 추가
  Future<void> _sendLocationMessage(
    String locationName,
    String locationUrl,
  ) async {
    if (_disposed) return;

    if (!isConnected) {
      addLog('위치 메시지 전송 실패: 연결되지 않음');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결 오류. 다시 시도해주세요.')));
      return;
    }

    try {
      final token = await _loginService.getAccessToken();
      if (_disposed) return;

      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
        return;
      }

      // 임시 메시지 생성 (UI 즉시 업데이트)
      final tempMessage = ChatMessage(
        text: locationName,
        isSent: true,
        time: TimeFormatter.getCurrentTime(),
        type: 'LOCATION',
        locationUrl: locationUrl,
        status: 'SENDING',
      );

      setState(() {
        _messages.add(tempMessage);
      });
      _scrollToBottom();

      // WebSocket으로 위치 메시지 전송
      final destination = '/pub/chat-room/${widget.roomId}';
      final messageJson = jsonEncode({
        "type": "LOCATION",
        "content": locationUrl, // API 명세서에 따라 URL을 content에 넣음
      });

      addLog('위치 메시지 전송 시도: $messageJson');

      stompClient.send(
        destination: destination,
        body: messageJson,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
          'chat_room_id': '${widget.roomId}',
        },
      );

      addLog('위치 메시지 전송 완료');
    } catch (e) {
      if (_disposed) return;
      addLog('위치 메시지 전송 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('위치 전송 중 오류가 발생했습니다: $e')));
      }
    }
  }

  // 갤러리에서 이미지 선택 메서드 개선
  Future<void> _getImageFromGallery() async {
    if (_disposed) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (!mounted) return;

      if (image != null) {
        final file = File(image.path);

        // 파일 존재 여부 확인
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
          });
          addLog('갤러리에서 이미지 선택: ${image.path}');

          // 이미지 메시지 전송
          await _sendImageMessage(file);
        } else {
          addLog('선택한 이미지 파일이 존재하지 않음: ${image.path}');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('이미지 파일을 찾을 수 없습니다.')));
        }
      }
    } catch (e) {
      if (_disposed) return;
      addLog('갤러리 접근 중 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('갤러리 접근 중 오류가 발생했습니다: $e')));
    }
  }

  // 카메라로 이미지 촬영 메서드 개선
  Future<void> _getImageFromCamera() async {
    if (_disposed) return; // mounted 대신 _disposed 사용

    try {
      // 카메라 권한 확인
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          addLog('카메라 권한이 거부되었습니다.');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('카메라 사용 권한이 필요합니다.')));
          }
          return;
        }
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (_disposed) return; // mounted 대신 _disposed 사용

      if (photo != null) {
        final file = File(photo.path);

        // 파일 존재 여부 및 크기 확인
        if (await file.exists()) {
          final fileSize = await file.length();
          setState(() {
            _selectedImage = file;
          });
          addLog('카메라로 사진 촬영: ${photo.path}, 파일 크기: ${fileSize}바이트');

          // 이미지 메시지 전송
          await _sendImageMessage(file);
        } else {
          addLog('카메라로 촬영한 이미지 파일이 존재하지 않음: ${photo.path}');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('이미지 파일을 찾을 수 없습니다.')));
        }
      }
    } catch (e) {
      addLog('카메라 접근 중 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('카메라 접근 중 오류가 발생했습니다: $e')));
    }
  }

  // 위치 선택기 다이얼로그 추가
  void _showLocationSelector() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('위치 공유'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('현재 위치'),
                  onTap: () {
                    Navigator.pop(context);
                    // LocationSelect 위젯으로 이동 (현재 위치에서 시작)
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LocationSelect()),
                    ).then((result) {
                      if (result != null && result is Map<String, dynamic>) {
                        // 위치 정보 추출
                        double latitude = result['latitude'] ?? 0.0;
                        double longitude = result['longitude'] ?? 0.0;

                        // Google Maps URL 생성
                        String locationUrl =
                            'https://maps.google.com/?q=$latitude,$longitude';

                        // 위치 메시지 전송 - locationName 제거
                        _sendLocationMessage('', locationUrl);
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('위치 검색'),
                  onTap: () {
                    Navigator.pop(context);
                    _showLocationSearchDialog();
                  },
                ),
              ],
            ),
          ),
    );
  }

  // 위치 검색 다이얼로그
  // 위치 검색 다이얼로그 대신 location_select.dart 위젯으로 이동
  void _showLocationSearchDialog() {
    if (!mounted) return;

    // LocationSelect 위젯으로 네비게이션
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationSelect()),
    ).then((result) {
      // 결과가 반환된 경우 (위치가 선택된 경우)
      if (result != null && result is Map<String, dynamic>) {
        // 위치 정보 추출
        String locationName = result['location'] ?? '선택한 위치';
        double latitude = result['latitude'] ?? 0.0;
        double longitude = result['longitude'] ?? 0.0;

        // Google Maps URL 생성
        String locationUrl = 'https://maps.google.com/?q=$latitude,$longitude';

        // 위치 메시지 전송
        _sendLocationMessage(locationName, locationUrl);
      }
    });
  }

  void _showDeleteMessageDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('메시지 삭제'),
            content: const Text('로컬에 저장된 모든 메시지를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (context) =>
                            const Center(child: CircularProgressIndicator()),
                  );

                  final success = await _chatService.clearLocalMessages(
                    widget.roomId,
                  );
                  if (_disposed) return; // disposed 체크 추가

                  if (success) {
                    await _chatService.getNextCursor(widget.roomId);
                    if (_disposed) return; // disposed 체크 추가
                  }

                  // 로딩 닫기
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }

                  if (success) {
                    if (mounted) {
                      setState(() {
                        _messages = [];
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('모든 메시지가 삭제되었습니다')),
                      );
                    }
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('메시지 삭제 중 오류가 발생했습니다')),
                      );
                    }
                  }
                },
                child: const Text('삭제'),
              ),
            ],
          ),
    );
  }

  Map<String, dynamic>? _chatRoomDetail;

  Future<void> _loadChatRoomDetail() async {
    if (_disposed) return;

    try {
      final token = await _loginService.getAccessToken();
      if (_disposed) return;
      if (token == null) return;

      final detail = await _chatService.getChatRoomDetail(widget.roomId, token);
      if (_disposed) return;

      if (mounted && detail != null) {
        setState(() {
          _chatRoomDetail = detail;
        });
        addLog('채팅방 상세 정보 로드 성공');
      }
    } catch (e) {
      addLog('채팅방 상세 정보 로드 오류: $e');
    }
  }

  // ChatPage 클래스에 추가
  Future<void> _retryFailedMessage(ChatMessage failedMessage) async {
    if (_disposed) return;

    try {
      addLog('메시지 재전송 시도: ${failedMessage.messageId ?? "ID 없음"}');

      // 메시지 재전송 중임을 표시
      setState(() {
        final index = _messages.indexOf(failedMessage);
        if (index != -1) {
          _messages[index].status = 'SENDING';
        }
      });

      // 메시지 타입에 따라 다른 재전송 로직
      if (failedMessage.type == 'IMAGE' && failedMessage.imageFile != null) {
        // 이미지 메시지 재전송
        await _sendImageMessage(failedMessage.imageFile!);
      } else if (failedMessage.type == 'LOCATION' &&
          failedMessage.locationUrl != null) {
        // 위치 메시지 재전송
        await _sendLocationMessage(
          failedMessage.text,
          failedMessage.locationUrl!,
        );
      } else {
        // 일반 텍스트 메시지 재전송
        sendMessage(failedMessage.text);
      }

      // 실패한 원래 메시지 제거 (새 메시지가 추가될 것이므로)
      setState(() {
        _messages.remove(failedMessage);
      });
    } catch (e) {
      if (_disposed) return;
      // 오류 처리
      setState(() {
        final index = _messages.indexOf(failedMessage);
        if (index != -1) {
          _messages[index].status = 'FAILED';
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 재전송 중 오류가 발생했습니다: $e')));
      }

      addLog('메시지 재전송 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.otherUserName,
        onBackPressed: () {
          // 모든 웹소켓 연결과 구독을 취소
          try {
            if (stompClient.connected) {
              // 모든 구독 취소
              if (chatRoomUnsubscribeFn != null) chatRoomUnsubscribeFn!();
              if (errorUnsubscribeFn != null) errorUnsubscribeFn!();
              if (readStatusUnsubscribeFn != null) readStatusUnsubscribeFn!();

              // 연결 종료
              stompClient.deactivate();
            }
          } catch (e) {
            print('뒤로가기 중 WebSocket 정리 오류: $e');
          }

          // 화면 이동
          Navigator.pop(context);
        },
        onClosePressed: () {
          // 모든 이전 라우트를 제거하고 홈으로 이동
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        customActions: [
          // 연결 상태 표시
          Center(
            child: Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? Colors.green : Colors.red,
              ),
            ),
          ),
          // 메시지 삭제 버튼 추가
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteMessageDialog();
            },
          ),
          // 더보기 버튼
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 35,
                height: 35,
                child: IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    if (!mounted) return;

                    // 더보기 버튼 동작
                    showModalBottomSheet(
                      context: context,
                      builder:
                          (context) => Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.refresh),
                                title: const Text('재연결'),
                                onTap: () {
                                  Navigator.pop(context);
                                  reconnect();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.bug_report),
                                title: Text(
                                  showDebugPanel ? '디버그 패널 숨기기' : '디버그 패널 표시',
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  if (!mounted) return;
                                  setState(() {
                                    showDebugPanel = !showDebugPanel;
                                  });
                                },
                              ),
                            ],
                          ),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: SafeArea(
          child: Column(
            children: [
              ProductInfoWidget(
                foundItemInfo:
                    _chatRoomDetail != null
                        ? _chatRoomDetail!['found_item']
                        : null,
              ),
              InfoBannerWidget(
                otherUserNickname: widget.otherUserName,
                myNickname: widget.myName,
                chatRoomId: widget.roomId,
              ),
              // DateDividerWidget(date: '3월 23일'),
              // 디버그 패널 (토글 가능)
              if (showDebugPanel)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.grey[800],
                        child: Row(
                          children: [
                            const Text(
                              '웹소켓 로그',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 16,
                              ),
                              onPressed: () {
                                if (!mounted) return;
                                setState(() {
                                  logs.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          reverse: true,
                          itemCount: logs.length,
                          itemBuilder: (context, index) {
                            final logIndex = logs.length - 1 - index;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                logs[logIndex],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // 메시지 목록 - 페이지네이션 지원
              // 메시지 목록 - 페이지네이션 지원
              Expanded(
                child:
                    _isLoading && _messages.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _messages.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '메시지가 없습니다.',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '첫 메시지를 보내 대화를 시작해보세요!',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                        : NotificationListener<ScrollNotification>(
                          onNotification: (ScrollNotification scrollInfo) {
                            // 스크롤이 맨 위에서 일정 거리 이내에 있고 로드 중이 아닐 때 더 많은 메시지 로드
                            if (!_isLoading &&
                                _hasMoreMessages &&
                                scrollInfo.metrics.pixels <=
                                    scrollInfo.metrics.minScrollExtent + 100) {
                              _loadMoreMessages();
                            }
                            return true;
                          },
                          child: ChatMessagesList(
                            messages: _messages,
                            scrollController: _scrollController,
                            onRetryMessage: _retryFailedMessage,
                          ),
                        ),
              ),
              ChatInputField(
                textController: _textController,
                onSubmitted: _handleSubmitted,
                onAttachmentPressed: () {
                  if (!mounted) return;
                  _showAddOptionsBottomSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptionsBottomSheet(BuildContext context) {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => AddOptionsPopup(
            onAlbumPressed: () {
              Navigator.pop(context);
              _getImageFromGallery();
            },
            onCameraPressed: () {
              Navigator.pop(context);
              _getImageFromCamera();
            },
            onLocationPressed: () {
              Navigator.pop(context);
              // 위치 선택기 표시
              _showLocationSelector();
            },
          ),
    );
  }
}
