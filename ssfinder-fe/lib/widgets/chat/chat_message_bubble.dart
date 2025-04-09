import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/chat_message.dart';
import 'dart:io';

class ChatMessagesList extends StatefulWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Function(ChatMessage)? onRetryMessage; // 재시도 콜백 추가

  const ChatMessagesList({
    Key? key,
    required this.messages,
    required this.scrollController,
    this.onRetryMessage, // 콜백 추가
  }) : super(key: key);

  @override
  State<ChatMessagesList> createState() => _ChatMessagesListState();
}

class _ChatMessagesListState extends State<ChatMessagesList> {
  @override
  Widget build(BuildContext context) {
    print('ChatMessagesList.build 호출됨');
    print('전달받은 메시지 개수: ${widget.messages.length}');

    // 메시지가 없을 때 처리
    if (widget.messages.isEmpty) {
      return const Center(child: Text('메시지가 없습니다. 대화를 시작해보세요.'));
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      reverse: true, // 최신 메시지가 맨 아래(또는 화면 상으로는 맨 위)에 표시됨
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];

        // widget.onRetryMessage 콜백을 retryCallback으로 전달
        if (message.isSent) {
          if (message.type == 'IMAGE') {
            return SentImageBubble(
              imageUrl: message.imageUrl ?? '',
              imageFile: message.imageFile,
              time: message.time,
              status: message.status,
              onRetry:
                  message.status == 'FAILED'
                      ? () => widget.onRetryMessage?.call(message)
                      : null,
            );
          } else if (message.type == 'LOCATION') {
            return SentMessageBubble(
              message: message.text,
              time: message.time,
              status: message.status,
              onRetry:
                  message.status == 'FAILED'
                      ? () => widget.onRetryMessage?.call(message)
                      : null,
            );
          } else {
            return SentMessageBubble(
              message: message.text,
              time: message.time,
              status: message.status,
              onRetry:
                  message.status == 'FAILED'
                      ? () => widget.onRetryMessage?.call(message)
                      : null,
            );
          }
        } else {
          // 받은 메시지
          if (message.type == 'IMAGE') {
            return ReceivedImageBubble(
              imageUrl: message.imageUrl ?? '',
              time: message.time,
            );
          } else if (message.type == 'LOCATION') {
            // LOCATION 타입 처리
            return ReceivedMessageBubble(
              message: message.text,
              time: message.time,
            );
          } else {
            return ReceivedMessageBubble(
              message: message.text,
              time: message.time,
            );
          }
        }
      },
    );
  }
}

class SentImageBubble extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final String time;
  final String status;
  final Function()? onRetry; // 재시도 콜백 추가

  const SentImageBubble({
    Key? key,
    this.imageUrl,
    this.imageFile,
    required this.time,
    this.status = 'UNREAD',
    this.onRetry, // 재시도 콜백 추가
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 읽음 표시 또는 재시도 버튼
            if (status == 'READ')
              Text(
                '읽음',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              )
            else if (status == 'FAILED' && onRetry != null)
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 12, color: Colors.red[700]),
                      const SizedBox(width: 2),
                      Text(
                        '재시도',
                        style: TextStyle(fontSize: 10, color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 4),
            // 기존 시간 표시
            Text(
              time,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    status == 'FAILED'
                        ? Colors.red[100]
                        : const Color(0xFF619BF7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    imageFile != null
                        ? Image.file(imageFile!, width: 200, fit: BoxFit.cover)
                        : Image.network(
                          imageUrl ?? '',
                          width: 200,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            // 기존 코드
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 200,
                              height: 150,
                              color: Colors.white.withOpacity(0.3),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress
                                                  .cumulativeBytesLoaded /
                                              loadingProgress
                                                  .expectedTotalBytes!
                                          : null,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            // 기존 코드
                            return Container(
                              width: 200,
                              height: 40,
                              color: Colors.white.withOpacity(0.3),
                              child: const Center(
                                child: Text(
                                  '이미지 로드 실패',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceivedMessageBubble extends StatelessWidget {
  final String message;
  final String time;

  const ReceivedMessageBubble({
    Key? key,
    required this.message,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        // 고정 높이 대신 IntrinsicHeight 사용
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: Text(
                      message,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SvgPicture.asset(
                  'assets/images/chat/avatar_icon.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceivedImageBubble extends StatelessWidget {
  final String imageUrl;
  final String time;

  const ReceivedImageBubble({
    Key? key,
    required this.imageUrl,
    required this.time,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 150,
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 40,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Text(
                                '이미지 로드 실패',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SvgPicture.asset(
                  'assets/images/chat/avatar_icon.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReceivedMessageWithMap extends StatelessWidget {
  const ReceivedMessageWithMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.6,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAEAEA),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomLeft: Radius.circular(0),
                        bottomRight: Radius.circular(15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '여기서 만날까요?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(
                            'assets/images/chat/map_image.png',
                            width: 230,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '삼성전자 광주사업장 | 구글맵',
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF888888),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '10:14',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              bottom: -16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SvgPicture.asset(
                  'assets/images/chat/avatar_icon.svg',
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// SentMessageBubble 클래스 수정 (FAILED 상태일 때 재시도 버튼 표시)
class SentMessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final String status;
  final Function()? onRetry; // 재시도 콜백 추가

  const SentMessageBubble({
    Key? key,
    required this.message,
    required this.time,
    this.status = 'UNREAD',
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 읽음 표시 또는 재시도 버튼
            if (status == 'READ')
              Text(
                '읽음',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              )
            else if (status == 'FAILED' && onRetry != null)
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 12, color: Colors.red[700]),
                      const SizedBox(width: 2),
                      Text(
                        '재시도',
                        style: TextStyle(fontSize: 10, color: Colors.red[700]),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 4),
            // 기존 시간 표시
            Text(
              time,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: Colors.grey[500]),
            ),
            const SizedBox(width: 8),
            // 메시지 버블
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    status == 'FAILED'
                        ? Colors.red[100]
                        : const Color(0xFF619BF7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(0),
                ),
              ),
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: status == 'FAILED' ? Colors.red[900] : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
