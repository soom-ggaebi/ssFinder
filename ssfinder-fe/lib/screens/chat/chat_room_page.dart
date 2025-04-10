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
  int? currentUserId; // 현재 사용자 ID

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

  // 권한 확인 메서드 추가
  Future<void> _checkPermissions() async {
    if (_disposed) return;
    
    // camera와 storage 권한 요청
    Map<Permission, PermissionStatus> statuses =
        await [Permission.camera, Permission.storage].request();
    if (_disposed) return;
    
    addLog('카메라 권한: ${statuses[Permission.camera]}');
    addLog('저장소 권한: ${statuses[Permission.storage]}');
  }
  
  @override
  void initState() {
    super.initState();
    print('ChatPage 초기화');
    
    // API 호출 차단 상태 해제
    _chatService.unblockApi(widget.roomId).then((_) {
      print('API 호출 차단 상태 해제됨');
    });
    
    // 추가한 _checkPermissions 호출
    _checkPermissions();
    
    // 의도적 연결 해제 상태 확인 및 사용자 정보 초기화 등...
    _chatService.isIntentionallyDisconnected(widget.roomId).then((isIntentional) {
      if (isIntentional) {
        _chatService.resetDisconnectState(widget.roomId).then((_) {
          _initializeUserData().then((_) {
            print('사용자 초기화 완료 - ID: $currentUserId');
            if (currentUserId != null) {
              _loadInitialMessages();
              _loadChatRoomDetail();
              setupAutoReconnect();
            } else {
              print('사용자 ID가 초기화되지 않았습니다. 메시지를 로드할 수 없습니다.');
            }
          });
        });
      } else {
        _initializeUserData().then((_) {
          print('사용자 초기화 완료 - ID: $currentUserId');
          if (currentUserId != null) {
            _loadInitialMessages();
            _loadChatRoomDetail();
            setupAutoReconnect();
          } else {
            print('사용자 ID가 초기화되지 않았습니다. 메시지를 로드할 수 없습니다.');
          }
        });
      }
    });
  }

  Future<bool> _manageConnection() async {
    if (_isInitializingClient || _isReconnecting) {
      print('🟡 연결 작업이 이미 진행 중입니다');
      return false;
    }

    final shouldConnect = await _chatService.shouldAttemptReconnect(widget.roomId);
    if (!shouldConnect) {
      print('🔴 의도적으로 연결이 해제된 상태입니다');
      return false;
    }

    if (_isStompClientInitialized && stompClient.connected && isConnected) {
      print('🟢 이미 연결된 상태입니다');
      return true;
    }

    _cleanupExistingConnection();
    initStompClient();
    await Future.delayed(Duration(seconds: 2));
    return isConnected;
  }

  void _cleanupExistingConnection() {
    try {
      if (_isStompClientInitialized && stompClient.connected) {
        if (chatRoomUnsubscribeFn != null) {
          try {
            chatRoomUnsubscribeFn!();
          } catch (e) {
            print('채팅방 구독 취소 오류: $e');
          }
          chatRoomUnsubscribeFn = null;
        }
        if (errorUnsubscribeFn != null) {
          try {
            errorUnsubscribeFn!();
          } catch (e) {
            print('에러 구독 취소 오류: $e');
          }
          errorSubscriptionId = null;
        }
        if (readStatusUnsubscribeFn != null) {
          try {
            readStatusUnsubscribeFn!();
          } catch (e) {
            print('읽음 상태 구독 취소 오류: $e');
          }
          readStatusUnsubscribeFn = null;
        }

        _isSubscribingToReadStatus = false;
        _isSubscribingToChatRoom = false;
        _isSubscribingToErrors = false;

        stompClient.deactivate();
      }
    } catch (e) {
      print('💥 기존 연결 정리 중 오류: $e');
    }
  }

  Future<void> _initializeUserData() async {
    if (_disposed || currentUserId != null) return;

    await _fetchLatestToken();
    if (_disposed) return;

    try {
      final userProfile = await _loginService.getUserProfile();
      if (_disposed || userProfile == null) return;

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

        if (_currentToken != null && mounted) {
          final shouldConnect = await _chatService.shouldAttemptReconnect(widget.roomId);
          if (shouldConnect) {
            initStompClient();
          } else {
            print('사용자가 의도적으로 연결을 끊었으므로 STOMP 클라이언트 초기화를 건너뜁니다.');
          }
        }
      } else {
        print('사용자 ID를 유효한 정수로 변환할 수 없습니다.');
      }
    } catch (e) {
      print('사용자 프로필 가져오기 오류: $e');
    }
  }

  Future<void> _fetchLatestToken() async {
    if (_disposed) return;

    final shouldConnect = await _chatService.shouldAttemptReconnect(widget.roomId);
    if (!shouldConnect) {
      addLog('사용자가 의도적으로 연결을 끊었으므로 토큰 갱신 및 연결을 시도하지 않습니다.');
      return;
    }

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
    _disposed = true;
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }
    _textController.dispose();
    _scrollController.dispose();
    _cleanupExistingConnection();
    super.dispose();
  }

  void addLog(String log) {
    print('📝 [ChatPage] $log');
    if (!mounted) return;
    setState(() {
      logs.add('${DateTime.now().toString().substring(11, 19)}: $log');
      if (logs.length > 100) logs.removeAt(0);
    });
  }

  bool _isInitializingClient = false;

  Future<void> initStompClient() async {
    if (_isInitializingClient) {
      print('🟡 STOMP 클라이언트 초기화가 이미 진행 중입니다.');
      return;
    }

    final shouldConnect = await _chatService.shouldAttemptReconnect(widget.roomId);
    if (!shouldConnect) {
      print('🔴 의도적으로 연결이 해제되었으므로 STOMP 클라이언트 초기화를 건너뜁니다.');
      return;
    }

    _isInitializingClient = true;
    try {
      await _loginService.ensureAuthenticated();
      _currentToken = await _loginService.getAccessToken();

      if (_currentToken == null) {
        _isInitializingClient = false;
        print('🚫 토큰이 null입니다. STOMP 클라이언트 초기화를 중단합니다.');
        return;
      }

      final String serverUrl = 'wss://ssfinder.site/app/';
      stompClient = StompClient(
        config: StompConfig(
          url: serverUrl,
          onConnect: (frame) {
            print('🟢 STOMP 연결 성공');
            if (mounted) {
              if (!isConnected) {
                onConnect(frame);
              }
            }
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
            // 필요할 경우 활성화
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
      stompClient.activate();
      print('🚀 STOMP 클라이언트 활성화');
    } catch (e) {
      print('💥 STOMP 클라이언트 초기화 중 오류: $e');
    } finally {
      _isInitializingClient = false;
    }
  }

  bool _isSubscribingToReadStatus = false;
  bool _isSubscribingToChatRoom = false;
  bool _isSubscribingToErrors = false;

  void onConnect(StompFrame frame) {
    if (isConnected) {
      print('🟡 이미 연결된 상태에서 추가 연결 이벤트 수신. 무시합니다.');
      return;
    }

    addLog('연결 성공: ${frame.body}');
    if (!mounted) return;

    setState(() {
      isConnected = true;
      reconnectAttempts = 0;
    });

    Future.delayed(Duration(milliseconds: 500), () {
      if (!mounted || !stompClient.connected) return;
      if (!_isSubscribingToChatRoom) {
        _isSubscribingToChatRoom = true;
        subscribeToChatRoom();
      }
      if (!_isSubscribingToErrors) {
        _isSubscribingToErrors = true;
        subscribeToErrors();
      }
      if (!_isSubscribingToReadStatus) {
        _isSubscribingToReadStatus = true;
        subscribeToReadStatus();
      }
      _sendOnlineStatus();
      _processUnreadMessages();
    });
  }

  void _sendOnlineStatus() {
    try {
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
      stompClient.send(
        destination: '/app/connect',
        body: json.encode({"chat_room_id": widget.roomId}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
        },
      );
      addLog('연결 확인 메시지 전송 성공');
    } catch (e) {
      addLog('연결 확인 메시지 전송 실패: $e');
    }
  }

  void _processUnreadMessages() {
    if (currentUserId == null || _messages.isEmpty) return;
    final List<String> unreadMessageIds = _messages
        .where((msg) =>
            !msg.isSent &&
            msg.status == 'UNREAD' &&
            msg.messageId != null)
        .map((msg) => msg.messageId!)
        .toList();
    if (unreadMessageIds.isNotEmpty) {
      addLog('읽지 않은 메시지 ${unreadMessageIds.length}개 읽음 처리 시작');
      sendReadReceipt(unreadMessageIds);
    }
  }

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

  // 수정된 부분: subscribeToReadStatus에서 ChatMessage 생성 시 "sentAt:" 사용 (기존에 잘못되어 있던 "time:" 제거)
  void subscribeToReadStatus() {
    if (readStatusUnsubscribeFn != null) {
      try {
        readStatusUnsubscribeFn!();
        readStatusUnsubscribeFn = null;
      } catch (e) {
        print('읽음 상태 구독 취소 오류: $e');
      }
    }

    final String topic = '/sub/chat-room/${widget.roomId}/read';
    readStatusUnsubscribeFn = stompClient.subscribe(
      destination: topic,
      callback: (StompFrame frame) {
        if (frame.body == null || frame.body!.isEmpty) return;
        addLog('읽음 상태 업데이트 수신: ${frame.body}');
        final jsonData = json.decode(frame.body!);
        final int userId = jsonData['user_id'];
        final List<String> messageIds = List<String>.from(jsonData['message_ids']);
        final int chatRoomId = jsonData['chat_room_id'];
        if (userId != currentUserId) {
          addLog('상대방(ID: $userId)이 메시지 ${messageIds.length}개를 읽음');
          if (chatRoomId != widget.roomId) return;
          if (userId == currentUserId) return;
          setState(() {
            for (int i = 0; i < _messages.length; i++) {
              if (_messages[i].isSent && messageIds.contains(_messages[i].messageId)) {
                _messages[i] = ChatMessage(
                  text: _messages[i].text,
                  isSent: _messages[i].isSent,
                  sentAt: _messages[i].sentAt,  // 수정: "sentAt:" 사용
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

  void subscribeToChatRoom() {
    try {
      if (!stompClient.connected) {
        addLog('⚠️ 채팅방 구독 시도 실패: STOMP 클라이언트가 연결되지 않았습니다.');
        _isSubscribingToChatRoom = false;
        Future.delayed(Duration(seconds: 2), () {
          if (mounted && isConnected && !_isSubscribingToChatRoom) {
            _isSubscribingToChatRoom = true;
            subscribeToChatRoom();
          }
        });
        return;
      }
      if (chatRoomUnsubscribeFn != null) {
        try {
          chatRoomUnsubscribeFn!();
        } catch (e) {
          print('채팅방 구독 취소 오류: $e');
        }
        chatRoomUnsubscribeFn = null;
      }
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
            Map<String, dynamic> jsonData;
            try {
              jsonData = json.decode(frame.body!);
            } catch (e) {
              print('⚠️ JSON 파싱 오류: $e');
              print('⚠️ 원본 데이터: ${frame.body}');
              return;
            }
            addLog('메시지 수신: ${frame.body}');
            final int senderId = jsonData['sender_id'];
            final String content = jsonData['content'] as String? ?? '';
            final String type = jsonData['type'] as String? ?? 'NORMAL';
            final bool isImage = type == 'IMAGE';
            final bool isLocation = type == 'LOCATION';
            DateTime sentAt;
            try {
              sentAt = DateTime.parse(jsonData['sent_at']);
            } catch (_) {
              sentAt = DateTime.now();
            }
            final ChatMessage message = ChatMessage(
              text: (jsonData['type'] == 'IMAGE' || jsonData['type'] == 'LOCATION')
                  ? ''
                  : jsonData['content'] ?? '',
              isSent: senderId == currentUserId,
              sentAt: sentAt,
              type: jsonData['type'] ?? 'NORMAL',
              status: jsonData['status'] ?? 'UNREAD',
              messageId: jsonData['message_id'],
              imageUrl: jsonData['type'] == 'IMAGE' ? jsonData['content'] : null,
              locationUrl: jsonData['type'] == 'LOCATION' ? jsonData['content'] : null,
            );
            if (mounted) {
              _addOrUpdateMessage(message);
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
      addLog('✅ 채팅방 구독 완료: $topic');
    } catch (e) {
      _isSubscribingToChatRoom = false;
      addLog('❌ 채팅방 구독 중 오류: $e');
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
      errorUnsubscribeFn = stompClient.subscribe(
        destination: topic,
        callback: (StompFrame frame) {
          addLog('에러 수신: ${frame.body}');
          if (!mounted) return;
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

  void onWebSocketError(dynamic error) {
    addLog('WebSocket 오류: $error');
    if (!mounted) return;
    setState(() {
      isConnected = false;
    });
    if (mounted) {
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

  Timer? _reconnectTimer;

  Future<void> setupAutoReconnect() async {
    if (_reconnectTimer != null) {
      _reconnectTimer!.cancel();
      _reconnectTimer = null;
    }
    final shouldReconnect = await _chatService.shouldAttemptReconnect(widget.roomId);
    if (!shouldReconnect) {
      print('사용자가 의도적으로 연결을 끊었으므로 자동 재연결 타이머를 설정하지 않습니다.');
      return;
    }
    _reconnectTimer = Timer.periodic(const Duration(seconds: 60), (timer) async {
      if (_disposed) {
        timer.cancel();
        return;
      }
      final shouldAttemptReconnect = await _chatService.shouldAttemptReconnect(widget.roomId);
      if (!shouldAttemptReconnect) {
        timer.cancel();
        _reconnectTimer = null;
        addLog('사용자가 의도적으로 연결을 끊었으므로 자동 재연결 타이머를 취소합니다.');
        return;
      }
      if (!isConnected && reconnectAttempts < 5) {
        reconnectAttempts++;
        addLog('자동 재연결 시도 ($reconnectAttempts/5)...');
        await _manageConnection();
      } else if (isConnected) {
        reconnectAttempts = 0;
      }
    });
  }

  bool _isReconnecting = false;

  Future<void> reconnect() async {
    if (_disposed) return;
    if (_isReconnecting) {
      addLog('이미 재연결 중입니다.');
      return;
    }
    final shouldReconnect = await _chatService.shouldAttemptReconnect(widget.roomId);
    if (!shouldReconnect) {
      addLog('사용자가 의도적으로 연결을 끊었으므로 재연결 시도하지 않음');
      return;
    }
    _isReconnecting = true;
    try {
      if (_isStompClientInitialized && stompClient.connected) {
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
        if (readStatusUnsubscribeFn != null) {
          try {
            readStatusUnsubscribeFn!();
            readStatusUnsubscribeFn = null;
          } catch (e) {
            addLog('읽음 상태 구독 취소 중 오류: $e');
          }
        }
        stompClient.deactivate();
      }
    } catch (e) {
      addLog('연결 종료 중 오류: $e');
    } finally {
      _isReconnecting = false;
    }
    initStompClient();
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

  void sendMessage(String text) {
    if (!isConnected) return;
    final destination = '/pub/chat-room/${widget.roomId}';
    final messageJson = jsonEncode({
      "type": "NORMAL",
      "content": text,
      "chat_room_id": widget.roomId,
      "sender_id": currentUserId,
    });
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
    addLog('메시지 전송 완료');
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    if (!mounted) return;
    if (!isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연결 오류. 다시 시도해주세요.')));
      return;
    }
    String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = ChatMessage(
      text: text,
      isSent: true,
      sentAt: DateTime.now(),
      type: 'NORMAL',
      status: 'SENDING',
      messageId: tempId,
    );
    setState(() {
      _messages.insert(0, tempMessage);
      _sortMessages();
    });
    _scrollToBottom();
    sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.minScrollExtent;
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendImageMessage(File imageFile) async {
    if (_disposed) return;
    try {
      final token = await _loginService.getAccessToken();
      if (_disposed) return;
      if (token == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
        return;
      }
      if (currentUserId == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('사용자 정보를 가져올 수 없습니다')));
        return;
      }
      final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = ChatMessage(
        text: '',
        isSent: true,
        sentAt: DateTime.now(),
        type: 'IMAGE',
        imageFile: imageFile,
        status: 'SENDING',
        messageId: tempId,
      );
      setState(() {
        _messages.insert(0, tempMessage);
      });
      _scrollToBottom();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      final fileSize = await imageFile.length();
      addLog('이미지 전송 시작: ${imageFile.path}, 파일 크기: $fileSize 바이트');
      final result = await _chatService.uploadImage(
        imageFile,
        widget.roomId,
        currentUserId!,
        token,
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (result != null) {
        setState(() {
          final index = _messages.indexWhere((msg) => msg.messageId == tempId);
          if (index != -1) {
            _messages[index] = result;
            addLog('이미지 메시지 업데이트 완료: ${result.imageUrl}');
          } else {
            _messages.insert(0, result);
            addLog('이미지 메시지 추가 완료: ${result.imageUrl}');
          }
        });
        _chatService.addMessageToLocal(widget.roomId, result);
        addLog('이미지 전송 성공: ${result.imageUrl}');
      } else {
        setState(() {
          final index = _messages.indexWhere((msg) => msg.messageId == tempId);
          if (index != -1) {
            _messages[index].status = 'FAILED';
          }
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('이미지 전송 실패')));
      }
    } catch (e) {
      if (_disposed) return;
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('이미지 전송 중 오류가 발생했습니다: $e')));
      addLog('이미지 전송 오류: $e');
    }
  }

  Future<void> _sendLocationMessage(String locationName, String locationUrl) async {
    if (_disposed) return;
    if (!isConnected) {
      addLog('위치 메시지 전송 실패: 연결되지 않음');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('연결 오류. 다시 시도해주세요.')));
      return;
    }
    try {
      final token = await _loginService.getAccessToken();
      if (_disposed) return;
      if (token == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
        return;
      }
      final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final tempMessage = ChatMessage(
        text: locationName,
        isSent: true,
        sentAt: DateTime.now(),
        type: 'LOCATION',
        locationUrl: locationUrl,
        status: 'SENDING',
        messageId: tempId,
      );
      setState(() {
        _messages.add(tempMessage);
      });
      _scrollToBottom();
      final destination = '/pub/chat-room/${widget.roomId}';
      final messageJson = jsonEncode({
        "type": "LOCATION",
        "content": locationUrl,
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
      Future.delayed(const Duration(seconds: 2), () {
        final index = _messages.indexWhere((msg) => msg.messageId == tempId);
        if (index != -1 && _messages[index].status == 'SENDING') {
          setState(() {
            _messages[index].status = 'SENT';
          });
          addLog('임시 위치 메시지 상태를 SENDING에서 SENT로 업데이트');
        }
      });
    } catch (e) {
      if (_disposed) return;
      addLog('위치 메시지 전송 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('위치 전송 중 오류가 발생했습니다: $e')));
      }
    }
  }

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
        if (await file.exists()) {
          setState(() {
            _selectedImage = file;
          });
          addLog('갤러리에서 이미지 선택: ${image.path}');
          await _sendImageMessage(file);
        } else {
          addLog('선택한 이미지 파일이 존재하지 않음: ${image.path}');
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('이미지 파일을 찾을 수 없습니다.')));
        }
      }
    } catch (e) {
      if (_disposed) return;
      addLog('갤러리 접근 중 오류: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('갤러리 접근 중 오류가 발생했습니다: $e')));
    }
  }

  Future<void> _getImageFromCamera() async {
    if (_disposed) return;
    try {
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          addLog('카메라 권한이 거부되었습니다.');
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('카메라 사용 권한이 필요합니다.')));
          }
          return;
        }
      }
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );
      if (_disposed) return;
      if (photo != null) {
        final file = File(photo.path);
        if (await file.exists()) {
          final fileSize = await file.length();
          setState(() {
            _selectedImage = file;
          });
          addLog('카메라로 사진 촬영: ${photo.path}, 파일 크기: ${fileSize}바이트');
          await _sendImageMessage(file);
        } else {
          addLog('카메라로 촬영한 이미지 파일이 존재하지 않음: ${photo.path}');
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('이미지 파일을 찾을 수 없습니다.')));
        }
      }
    } catch (e) {
      addLog('카메라 접근 중 오류: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('카메라 접근 중 오류가 발생했습니다: $e')));
    }
  }

  void _showLocationSelector() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 공유'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('현재 위치'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LocationSelect()),
                ).then((result) {
                  if (result != null && result is Map<String, dynamic>) {
                    double latitude = result['latitude'] ?? 0.0;
                    double longitude = result['longitude'] ?? 0.0;
                    String locationUrl = 'https://maps.google.com/?q=$latitude,$longitude';
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

  void _showLocationSearchDialog() {
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LocationSelect()),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        String locationName = result['location'] ?? '선택한 위치';
        double latitude = result['latitude'] ?? 0.0;
        double longitude = result['longitude'] ?? 0.0;
        String locationUrl = 'https://maps.google.com/?q=$latitude,$longitude';
        _sendLocationMessage(locationName, locationUrl);
      }
    });
  }

  void _showDeleteMessageDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              final success = await _chatService.clearLocalMessages(widget.roomId);
              if (_disposed) return;
              if (success) {
                await _chatService.getNextCursor(widget.roomId);
                if (_disposed) return;
              }
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

  Future<void> _retryFailedMessage(ChatMessage failedMessage) async {
    if (_disposed) return;
    try {
      addLog('메시지 재전송 시도: ${failedMessage.messageId ?? "ID 없음"}');
      setState(() {
        final index = _messages.indexOf(failedMessage);
        if (index != -1) {
          _messages[index].status = 'SENDING';
        }
      });
      if (failedMessage.type == 'IMAGE' && failedMessage.imageFile != null) {
        await _sendImageMessage(failedMessage.imageFile!);
      } else if (failedMessage.type == 'LOCATION' &&
          failedMessage.locationUrl != null) {
        await _sendLocationMessage(
          failedMessage.text,
          failedMessage.locationUrl!,
        );
      } else {
        sendMessage(failedMessage.text);
      }
      setState(() {
        _messages.remove(failedMessage);
      });
    } catch (e) {
      if (_disposed) return;
      setState(() {
        final index = _messages.indexOf(failedMessage);
        if (index != -1) {
          _messages[index].status = 'FAILED';
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('메시지 재전송 중 오류가 발생했습니다: $e')));
      }
      addLog('메시지 재전송 오류: $e');
    }
  }

  void _sortMessages() {
    _messages.sort((a, b) => b.sentAt.compareTo(a.sentAt));
  }

  void _addOrUpdateMessage(ChatMessage message) {
    if (!mounted) return;
    setState(() {
      int existingIndex = -1;
      if (message.messageId != null) {
        existingIndex = _messages.indexWhere((msg) => msg.messageId == message.messageId);
      }
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
        _messages[existingIndex] = message;
      } else {
        _messages.insert(0, message);
      }
      _sortMessages();
    });
  }

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
      print('메시지 로딩 - roomId: ${widget.roomId}, 커서: $cursor, 페이지 크기: $_pageSize');
      final messages = await _chatService.loadMessages(
        widget.roomId,
        size: _pageSize,
        cursor: cursor,
        userId: currentUserId,
        forceRefresh: true,
      );
      print('로드된 메시지 수: ${messages.length}');
      if (_disposed) return;
      setState(() {
        if (isLoadMore) {
          for (final m in messages) {
            if (!_messages.any((e) => e.messageId == m.messageId)) {
              _messages.add(m);
            }
          }
        } else {
          _messages = messages;
          _sortMessages();
        }
        _isLoading = false;
      });
      _nextCursor = await _chatService.getNextCursor(widget.roomId);
      _hasMoreMessages = _nextCursor != null && _nextCursor!.isNotEmpty;
      print('다음 커서: $_nextCursor, 추가 메시지 여부: $_hasMoreMessages');
      print('현재 메시지 개수: ${_messages.length}');
    } catch (e) {
      print('메시지 로드 중 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMoreMessages() {
    if (!_isLoading && _hasMoreMessages && _nextCursor != null && _nextCursor!.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });
      _loadMessagesFromApi(isLoadMore: true).then((_) {
        setState(() {
          _isLoading = false;
        });
      });
    }
  }

  Future<void> _loadInitialMessages() async {
    if (_disposed) return;
    setState(() {
      _isLoading = true;
      _messages = [];
      _hasMoreMessages = true;
      _nextCursor = null;
    });
    try {
      await _chatService.unblockApi(widget.roomId);
      await _loadMessagesFromApi();
      if (_disposed) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.otherUserName,
        onBackPressed: () async {
          await _chatService.markIntentionalDisconnect(widget.roomId, true);
          _cleanupExistingConnection();
          if (_reconnectTimer != null) {
            _reconnectTimer!.cancel();
            _reconnectTimer = null;
          }
          Navigator.pop(context);
        },
        onClosePressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        customActions: [
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
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteMessageDialog();
            },
          ),
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
                    showModalBottomSheet(
                      context: context,
                      builder: (context) => Column(
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
                foundItemInfo: _chatRoomDetail != null ? _chatRoomDetail!['found_item'] : null,
              ),
              InfoBannerWidget(
                otherUserNickname: widget.otherUserName,
                myNickname: widget.myName,
                chatRoomId: widget.roomId,
              ),
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
              Expanded(
                child: _isLoading && _messages.isEmpty
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
                              if (!_isLoading &&
                                  _hasMoreMessages &&
                                  scrollInfo.metrics.pixels <= scrollInfo.metrics.minScrollExtent + 100) {
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
      builder: (context) => AddOptionsPopup(
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
          _showLocationSelector();
        },
      ),
    );
  }
}
