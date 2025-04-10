import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../../models/chat_message.dart';

class ChatMessagesList extends StatefulWidget {
  final List<ChatMessage> messages;
  final ScrollController scrollController;
  final Function(ChatMessage)? onRetryMessage;

  const ChatMessagesList({
    Key? key,
    required this.messages,
    required this.scrollController,
    this.onRetryMessage,
  }) : super(key: key);

  @override
  State<ChatMessagesList> createState() => _ChatMessagesListState();
}

class _ChatMessagesListState extends State<ChatMessagesList> {
  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return const Center(child: Text('메시지가 없습니다. 대화를 시작해보세요.'));
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      reverse: true,
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];

        if (message.isSent) {
          if (message.type == 'IMAGE') {
            return SentImageBubble(
              imageUrl: message.imageUrl ?? '',
              imageFile: message.imageFile,
              time: message.time,
              status: message.status,
              onRetry: message.status == 'FAILED'
                  ? () => widget.onRetryMessage?.call(message)
                  : null,
            );
          } else if (message.type == 'LOCATION') {
            return SentLocationBubble(
              locationUrl: message.locationUrl,
              time: message.time,
              status: message.status,
              onRetry: message.status == 'FAILED'
                  ? () => widget.onRetryMessage?.call(message)
                  : null,
            );
          } else {
            return SentMessageBubble(
              message: message.text,
              time: message.time,
              status: message.status,
              onRetry: message.status == 'FAILED'
                  ? () => widget.onRetryMessage?.call(message)
                  : null,
            );
          }
        } else {
          if (message.type == 'IMAGE') {
            return ReceivedImageBubble(
              imageUrl: message.imageUrl ?? '',
              time: message.time,
            );
          } else if (message.type == 'LOCATION') {
            return ReceivedLocationBubble(
              locationUrl: message.locationUrl ?? '',
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

/// 보낸 이미지 메시지
class SentImageBubble extends StatelessWidget {
  final String? imageUrl;
  final File? imageFile;
  final String time;
  final String status;
  final Function()? onRetry; // 재시도 콜백

  const SentImageBubble({
    Key? key,
    this.imageUrl,
    this.imageFile,
    required this.time,
    this.status = 'UNREAD',
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 상태 및 재시도 버튼
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
          // 시간 표시
          Text(
            time,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.grey[500]),
          ),
          const SizedBox(width: 8),
          // 이미지 버블
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: status == 'FAILED'
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
              // SizedBox로 크기를 고정해서 일관된 레이아웃 유지
              child: SizedBox(
                width: 200,
                height: 150,
                child: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? Image.network(
                        imageUrl!,
                        width: 200,
                        height: 150,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: 200,
                            height: 150,
                            color: Colors.white.withOpacity(0.3),
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 150,
                            color: Colors.white.withOpacity(0.3),
                            child: const Center(
                              child: Text(
                                '이미지 로드 실패',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          );
                        },
                      )
                    : (imageFile != null
                        ? Image.file(
                            imageFile!,
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 200,
                            height: 150,
                            color: Colors.white.withOpacity(0.3),
                            child: const Center(
                              child: Text(
                                '이미지 로드 실패',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// 보낸 위치 메시지
class SentLocationBubble extends StatelessWidget {
  final String? locationUrl;
  final String time;
  final String status;
  final VoidCallback? onRetry;

  const SentLocationBubble({
    Key? key,
    this.locationUrl,
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
            if (status == 'READ')
              Text('읽음',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]))
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
                      Text('재시도',
                          style:
                              TextStyle(fontSize: 10, color: Colors.red[700])),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Text(time,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey[500])),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                if (locationUrl != null && locationUrl!.isNotEmpty) {
                  launchUrl(Uri.parse(locationUrl!));
                }
              },
              child: Container(
                constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: status == 'FAILED'
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
                  '위치 보기',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 보낸 일반 텍스트 메시지
class SentMessageBubble extends StatelessWidget {
  final String message;
  final String time;
  final String status;
  final VoidCallback? onRetry;

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
            if (status == 'READ')
              Text('읽음',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]))
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
                      Text('재시도',
                          style:
                              TextStyle(fontSize: 10, color: Colors.red[700])),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Text(time,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey[500])),
            const SizedBox(width: 8),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: status == 'FAILED'
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

/// 받은 이미지 메시지
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const SizedBox(width: 48), // 아바타 공간
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
                bottomLeft: Radius.circular(15),
                bottomRight: Radius.circular(15),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 200,
                height: 150,
                child: Image.network(
                  imageUrl,
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 150,
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 150,
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
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}


/// 받은 위치 메시지
class ReceivedLocationBubble extends StatelessWidget {
  final String locationUrl;
  final String time;

  const ReceivedLocationBubble({
    Key? key,
    required this.locationUrl,
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
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(locationUrl)),
                    child: Container(
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
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
                        '위치 보기',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(time,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.grey[500])),
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

/// 받은 일반 텍스트 메시지
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
                        maxWidth: MediaQuery.of(context).size.width * 0.6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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
                  Text(time,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: Colors.grey[500])),
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
