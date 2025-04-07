import 'package:flutter/material.dart';
import 'dart:io';
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
  int currentUserId = 15; // 현재 사용자 ID (실제 ID로 변경 필요)

  // STOMP 웹소켓 관련 변수
  late StompClient stompClient;
  bool isConnected = false;
  int reconnectAttempts = 0;
  // 구독 ID를 저장할 변수들 (구독 취소를 위해)
  String? chatRoomSubscriptionId;
  String? errorSubscriptionId;

  // 디버깅을 위한 로그
  final List<String> logs = [];
  bool showDebugPanel = false;

  @override
  void initState() {
    super.initState();
    _fetchLatestToken(); // 토큰을 먼저 가져오고 나서 STOMP 클라이언트 초기화
    _checkPermissions(); // 권한 확인 추가
  }

  // 권한 확인 메서드 추가
  Future<void> _checkPermissions() async {
    // 카메라 및 저장소 권한 확인
    Map<Permission, PermissionStatus> statuses =
        await [Permission.camera, Permission.storage].request();

    // 권한 상태 로깅
    addLog('카메라 권한: ${statuses[Permission.camera]}');
    addLog('저장소 권한: ${statuses[Permission.storage]}');
  }

  Future<void> _fetchLatestToken() async {
    final token = await _loginService.getAccessToken();
    setState(() {
      _currentToken = token;
    });

    // 토큰이 있으면 STOMP 클라이언트 초기화
    if (_currentToken != null) {
      initStompClient();
    } else {
      // 토큰이 없으면 로그인 화면으로 이동하는 로직
      addLog('토큰이 없습니다. 로그인이 필요합니다.');
    }
  }

  @override
  void dispose() {
    // 연결 상태와 상관없이 컨트롤러들 정리
    _textController.dispose();
    _scrollController.dispose();

    // WebSocket 정리
    try {
      if (stompClient.connected) {
        // 구독 취소 시도
        if (chatRoomUnsubscribeFn != null) {
          try {
            chatRoomUnsubscribeFn!();
            print('채팅방 구독 취소 완료');
          } catch (e) {
            print('채팅방 구독 취소 중 오류: $e');
          }
        }

        if (errorUnsubscribeFn != null) {
          try {
            errorUnsubscribeFn!();
            print('에러 구독 취소 완료');
          } catch (e) {
            print('에러 구독 취소 중 오류: $e');
          }
        }

        // 읽음 상태 구독 취소 추가
        if (readStatusUnsubscribeFn != null) {
          try {
            readStatusUnsubscribeFn!();
            print('읽음 상태 구독 취소 완료');
          } catch (e) {
            print('읽음 상태 구독 취소 중 오류: $e');
          }
        }

        // 연결 종료
        stompClient.deactivate();
        print('STOMP 클라이언트 비활성화 완료');
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

  // STOMP 클라이언트 초기화
  void initStompClient() {
    addLog('STOMP 클라이언트 초기화 시작');

    // WebSocket 서버 URL
    final String serverUrl = 'wss://ssfinder.site/app/';

    // STOMP 클라이언트 설정
    stompClient = StompClient(
      config: StompConfig(
        url: serverUrl,
        onConnect: (frame) {
          if (mounted) onConnect(frame);
        },
        onDisconnect: (frame) {
          if (mounted) onDisconnect(frame);
        },
        onWebSocketError: (error) {
          if (mounted) onWebSocketError(error);
        },
        onStompError: (frame) {
          if (mounted) onStompError(frame);
        },
        onDebugMessage: (String message) {
          addLog('디버그: $message');
        },
        // 포스트맨과 동일한 헤더 설정
        stompConnectHeaders: {
          'accept-version': '1.0,1.1,1.2',
          'heart-beat': '5000,5000',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
          'chat_room_id': '${widget.roomId}',
        },
      ),
    );

    addLog('STOMP 클라이언트 활성화');
    stompClient.activate();
  }

  // 연결 성공 시 호출
  void onConnect(StompFrame frame) {
    addLog('연결 성공: ${frame.body}');

    if (!mounted) return;

    setState(() {
      isConnected = true;
    });

    // 세션 ID 확인
    String? sessionId = frame.headers['session-id'];
    if (sessionId != null) {
      addLog('세션 ID: $sessionId');
    }

    // 채팅방 구독
    subscribeToChatRoom();

    // 에러 구독
    subscribeToErrors();

    // 읽음 상태 구독 추가
    subscribeToReadStatus();
  }

  // 읽음 상태 구독
  void subscribeToReadStatus() {
    final String topic = '/sub/chat-room/${widget.roomId}/read';

    addLog('읽음 상태 구독 시도: $topic');

    try {
      // 반환된 함수를 저장
      readStatusUnsubscribeFn = stompClient.subscribe(
        destination: topic,
        callback: (StompFrame frame) {
          addLog('읽음 상태 메시지 수신: ${frame.body}');

          if (!mounted) return;

          if (frame.body == null || frame.body!.isEmpty) {
            addLog('수신된 읽음 상태 메시지 본문이 비어있습니다');
            return;
          }

          try {
            final jsonData = json.decode(frame.body!);

            // 수신된 메시지가 현재 사용자의 메시지인지 확인
            final int userId = jsonData['user_id'] ?? -1;
            final List<dynamic> messageIds = jsonData['message_ids'] ?? [];

            // 내가 보낸 메시지에 대한 읽음 처리만 업데이트 (상대방이 읽었을 때)
            if (userId != currentUserId && messageIds.isNotEmpty) {
              addLog('상대방이 메시지를 읽음: ${messageIds.length}개');

              // 메시지 상태 업데이트 (messageId가 있는 경우 해당 메시지만 업데이트)
              if (messageIds.isNotEmpty) {
                for (var message in _messages) {
                  // messageId가 있고 messageIds 목록에 포함된 경우만 업데이트
                  if (message.isSent &&
                      message.status == 'UNREAD' &&
                      (message.messageId != null &&
                          messageIds.contains(message.messageId))) {
                    message.status = 'READ';
                    addLog('특정 메시지 상태 업데이트: messageId=${message.messageId}');
                  }
                }
              } else {
                // messageIds가 비어있는 경우 모든 보낸 메시지 업데이트 (이전 방식)
                for (var message in _messages) {
                  if (message.isSent && message.status == 'UNREAD') {
                    message.status = 'READ';
                    addLog(
                      '전체 메시지 상태 업데이트: ${message.text.isNotEmpty ? message.text.substring(0, min(10, message.text.length)) : "이미지"}',
                    );
                  }
                }
              }

              // 강제로 UI 갱신 (notifyListeners 동작이 안될 경우를 대비)
              setState(() {});

              addLog('메시지 읽음 상태 업데이트 완료');
            }
          } catch (e) {
            addLog('읽음 상태 처리 오류: $e');
          }
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
          'chat_room_id': '${widget.roomId}',
        },
      );

      addLog('읽음 상태 구독 성공');
    } catch (e) {
      addLog('읽음 상태 구독 오류: $e');
    }
  }

  // 채팅방 구독
  void subscribeToChatRoom() {
    final String topic = '/sub/chat-room/${widget.roomId}';

    addLog('채팅방 구독 시도: $topic');

    try {
      // 반환된 함수를 저장
      chatRoomUnsubscribeFn = stompClient.subscribe(
        destination: topic,
        callback: (StompFrame frame) {
          addLog('채팅 메시지 수신: ${frame.body}');

          if (!mounted) return; // mounted 상태 확인 추가

          if (frame.body == null || frame.body!.isEmpty) {
            addLog('수신된 메시지 본문이 비어있습니다');
            return;
          }

          try {
            final jsonData = json.decode(frame.body!);
            final messageType = jsonData['type'] ?? 'NORMAL';

            // 메시지 객체 생성
            late ChatMessage message;

            // 메시지 타입 확인 및 처리
            if (messageType == 'IMAGE') {
              // 이미지 메시지 처리
              addLog('이미지 메시지 수신: ${jsonData['content']}');

              // 새 ChatMessage 객체 생성
              message = ChatMessage(
                text: '',
                isSent: jsonData['sender_id'] == currentUserId,
                time: TimeFormatter.getCurrentTime(),
                type: 'IMAGE',
                imageUrl: jsonData['content'], // 이미지 URL 저장
                status: jsonData['status'] ?? 'UNREAD', // 상태 추가
                messageId: jsonData['message_id'], // 메시지 ID 추가
              );
            } else if (messageType == 'LOCATION') {
              // 위치 메시지 처리 추가
              addLog('위치 메시지 수신: ${jsonData['content']}');

              message = ChatMessage(
                text: jsonData['content'] ?? '',
                isSent: jsonData['sender_id'] == currentUserId,
                time: TimeFormatter.getCurrentTime(),
                type: 'LOCATION',
                locationUrl: jsonData['location_url'] ?? '',
                status: jsonData['status'] ?? 'UNREAD',
                messageId: jsonData['message_id'],
              );
            } else {
              // 일반 텍스트 메시지 처리
              message = ChatMessage(
                text: jsonData['content'] ?? '',
                isSent: jsonData['sender_id'] == currentUserId,
                time: TimeFormatter.getCurrentTime(),
                type: 'NORMAL',
                status: jsonData['status'] ?? 'UNREAD', // 상태 추가
                messageId: jsonData['message_id'], // 메시지 ID 추가
              );
            }

            if (!mounted) return;
            setState(() {
              _messages.add(message);
            });

            // 디버깅용 로그
            addLog('현재 메시지 개수: ${_messages.length}');
            addLog('마지막 메시지 타입: ${_messages.last.type}');
            if (messageType == 'IMAGE') {
              addLog('마지막 메시지 URL: ${_messages.last.imageUrl}');
            } else if (messageType == 'LOCATION') {
              addLog('마지막 메시지 위치: ${_messages.last.locationUrl}');
            }

            _scrollToBottom();
            addLog('채팅 수신 및 처리 완료');
          } catch (e) {
            addLog('메시지 처리 오류: $e');
          }
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_currentToken',
          'chat_room_id': '${widget.roomId}',
        },
      );

      addLog('채팅방 구독 성공');
    } catch (e) {
      addLog('채팅방 구독 오류: $e');
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

  // STOMP 오류 발생 시 호출
  void onStompError(StompFrame frame) {
    addLog('STOMP 오류: ${frame.body}');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('STOMP 프로토콜 오류가 발생했습니다'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> reconnect() async {
    addLog('재연결 시도');

    // 최신 토큰 가져오기
    await _fetchLatestToken();

    try {
      // 현재 클라이언트가 활성화된 경우 비활성화
      if (stompClient.connected) {
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

    // 웹소켓으로 메시지만 전송
    sendMessage(text);
  }

  // 메시지 전송
  void sendMessage(String text) {
    if (!mounted) return;

    if (!isConnected) {
      addLog('메시지 전송 실패: 연결되지 않음');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결 오류. 다시 시도해주세요.')));
      return;
    }

    if (text.trim().isEmpty) return;

    final destination = '/pub/chat-room/${widget.roomId}';
    final messageJson = jsonEncode({"type": "NORMAL", "content": text});

    addLog('메시지 전송 시도: $messageJson');

    try {
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
    } catch (e) {
      addLog('메시지 전송 오류: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 전송 중 오류가 발생했습니다: $e')));
      }
    }
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

  // 이미지 메시지 전송을 위한 개선된 메서드
  Future<void> _sendImageMessage(File imageFile) async {
    if (!mounted) return;

    try {
      // 최신 토큰 가져오기
      final token = await _loginService.getAccessToken();

      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
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

      setState(() {
        _messages.add(tempMessage);
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
        currentUserId,
        token,
      );

      // 로딩 닫기
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (result != null) {
        // 성공 시 임시 메시지 제거 (옵션)
        setState(() {
          _messages.removeWhere((msg) => msg == tempMessage);
          // 서버에서 웹소켓으로 메시지가 전송되면 자동으로 UI에 추가됨
        });
        addLog('이미지 전송 성공: ${result.imageUrl}');
      } else {
        // 실패 시 임시 메시지 상태 업데이트
        setState(() {
          // 임시 메시지 상태 변경
          tempMessage.status = 'FAILED';
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지 전송 실패')));
      }
    } catch (e) {
      // 로딩 닫기
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('이미지 전송 중 오류 발생: $e')));
      addLog('이미지 전송 오류: $e');
    }
  }

  // 위치 메시지 전송 메서드 추가
  Future<void> _sendLocationMessage(
    String locationName,
    String locationUrl,
  ) async {
    if (!mounted) return;

    if (!isConnected) {
      addLog('위치 메시지 전송 실패: 연결되지 않음');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결 오류. 다시 시도해주세요.')));
      return;
    }

    try {
      // 최신 토큰 가져오기
      final token = await _loginService.getAccessToken();

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
        "content": locationName,
        "location_url": locationUrl,
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
    if (!mounted) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // 품질 조정
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
      addLog('갤러리 접근 중 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('갤러리 접근 중 오류가 발생했습니다: $e')));
    }
  }

  // 카메라로 이미지 촬영 메서드 개선
  Future<void> _getImageFromCamera() async {
    if (!mounted) return;

    try {
      // 카메라 권한 확인
      var status = await Permission.camera.status;
      if (!status.isGranted) {
        status = await Permission.camera.request();
        if (!status.isGranted) {
          addLog('카메라 권한이 거부되었습니다.');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('카메라 사용 권한이 필요합니다.')));
          return;
        }
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // 품질 조정
      );

      if (!mounted) return;

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
                    // 현재 위치 가져오는 로직 (실제로는 위치 권한 확인 및 GPS 사용 필요)
                    _sendLocationMessage(
                      '현재 위치',
                      'https://maps.google.com/?q=현재위치',
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.search),
                  title: const Text('위치 검색'),
                  onTap: () {
                    Navigator.pop(context);
                    // 위치 검색 화면으로 이동 (실제로는 위치 검색 화면 구현 필요)
                    _showLocationSearchDialog();
                  },
                ),
              ],
            ),
          ),
    );
  }

  // 위치 검색 다이얼로그
  void _showLocationSearchDialog() {
    if (!mounted) return;

    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('위치 검색'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    hintText: '위치를 검색하세요',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final searchText = searchController.text.trim();
                    if (searchText.isNotEmpty) {
                      Navigator.pop(context);
                      // 검색어를 이용한 위치 전송 (실제로는 지도 API 연동 필요)
                      _sendLocationMessage(
                        searchText,
                        'https://maps.google.com/?q=${Uri.encodeComponent(searchText)}',
                      );
                    }
                  },
                  child: const Text('검색'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.otherUserName,
        onBackPressed: () {
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
              ProductInfoWidget(),
              InfoBannerWidget(
                otherUserId: widget.otherUserName,
                myId: widget.myName,
              ),
              DateDividerWidget(date: '3월 23일'),
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
              Expanded(
                child: ChatMessagesList(
                  messages: _messages,
                  scrollController: _scrollController,
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
