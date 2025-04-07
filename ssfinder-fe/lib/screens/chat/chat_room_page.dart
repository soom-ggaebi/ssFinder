import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:sumsumfinder/models/chat_message.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:sumsumfinder/widgets/chat/product_info.dart';
import 'package:sumsumfinder/widgets/chat/info_banner.dart';
import 'package:sumsumfinder/widgets/chat/date_divider.dart';
import 'package:sumsumfinder/widgets/chat/chat_input_field.dart';
import 'package:sumsumfinder/widgets/chat/chat_message_bubble.dart';
import 'package:sumsumfinder/utils/time_formatter.dart';
import 'package:sumsumfinder/widgets/chat/option_popups/add.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class ChatPage extends StatefulWidget {
  final String jwt;
  final int roomId;
  final String otherUserName;
  final String myName;

  const ChatPage({
    Key? key,
    required this.jwt,
    required this.roomId,
    required this.otherUserName,
    required this.myName,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];

  // STOMP 웹소켓 관련 변수
  late StompClient stompClient;
  bool isConnected = false;
  int reconnectAttempts = 0;

  // 디버깅을 위한 로그
  final List<String> logs = [];
  bool showDebugPanel = false;

  @override
  void initState() {
    super.initState();
    initStompClient();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    if (stompClient.connected) {
      stompClient.deactivate();
    }
    super.dispose();
  }

  // 로그 추가 함수
  void addLog(String log) {
    if (!mounted) return; // mounted 상태 확인 추가
    setState(() {
      logs.add('${DateTime.now().toString().substring(11, 19)}: $log');
      if (logs.length > 100) logs.removeAt(0);
    });
    print('📝 [ChatPage] $log');
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
        onConnect: onConnect,
        onDisconnect: onDisconnect,
        onWebSocketError: onWebSocketError,
        onStompError: onStompError,
        onDebugMessage: (String message) {
          addLog('디버그: $message');
        },
        // 포스트맨과 동일한 헤더 설정
        stompConnectHeaders: {
          'accept-version': '1.0,1.1,1.2',
          'heart-beat': '5000,5000',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.jwt}',
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
  }

  // 채팅방 구독
  void subscribeToChatRoom() {
    final String topic = '/sub/chat-room/${widget.roomId}';

    addLog('채팅방 구독 시도: $topic');

    try {
      stompClient.subscribe(
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

            // 메시지 객체 생성
            final message = ChatMessage(
              text: jsonData['content'] ?? '',
              isSent: jsonData['sender_id'] == 2,
              time: TimeFormatter.getCurrentTime(),
            );

            if (!mounted) return; // setState 전에 다시 한번 확인
            setState(() {
              _messages.add(message);
            });

            _scrollToBottom();
            addLog('채팅 수신 및 처리 완료');
          } catch (e) {
            addLog('메시지 처리 오류: $e');
          }
        },
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.jwt}',
          'chat_room_id': '${widget.roomId}',
        },
      );

      addLog('채팅방 구독 성공');
    } catch (e) {
      addLog('채팅방 구독 오류: $e');
    }
  }

  // 에러 구독
  void subscribeToErrors() {
    final String topic = '/user/queue/errors';

    addLog('에러 구독 시도: $topic');

    try {
      stompClient.subscribe(
        destination: topic,
        callback: (StompFrame frame) {
          addLog('에러 수신: ${frame.body}');

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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('STOMP 프로토콜 오류가 발생했습니다'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  // 재연결 시도
  void reconnect() {
    addLog('재연결 시도');

    // 현재 클라이언트가 활성화된 경우 비활성화
    if (stompClient.connected) {
      stompClient.deactivate();
    }

    // 새로운 연결 초기화
    initStompClient();
  }

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    _textController.clear();

    if (!isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('연결 오류. 다시 시도해주세요.')));
      return;
    }

    // 새 메시지 객체 생성 (UI 즉시 업데이트용)
    final message = ChatMessage(
      text: text,
      isSent: true,
      time: TimeFormatter.getCurrentTime(),
    );

    setState(() {
      _messages.add(message);
    });

    _scrollToBottom();

    // 웹소켓으로 메시지 전송
    sendMessage(text);
  }

  // 메시지 전송
  void sendMessage(String text) {
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
          'Authorization': 'Bearer ${widget.jwt}',
          'chat_room_id': '${widget.roomId}',
        },
      );

      addLog('메시지 전송 완료');
    } catch (e) {
      addLog('메시지 전송 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('메시지 전송 중 오류가 발생했습니다: $e')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _getImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
      addLog('갤러리에서 이미지 선택: ${image.path}');
      // 이미지 메시지 전송 로직 추가 필요
    }
  }

  Future<void> _getImageFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
      addLog('카메라로 사진 촬영: ${photo.path}');
      // 이미지 메시지 전송 로직 추가 필요
    }
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
              // 장소 관련 로직 추가
            },
          ),
    );
  }
}
