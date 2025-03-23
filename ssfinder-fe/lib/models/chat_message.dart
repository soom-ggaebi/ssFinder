import 'dart:io';

class ChatMessage {
  final String text;
  final bool isSent; // true면 보낸 메시지, false면 받은 메시지
  final String time;
  final File? image; // 이미지 메시지 지원 (옵션)
  final String? locationUrl; // 위치 메시지 지원 (옵션)

  ChatMessage({
    required this.text,
    required this.isSent,
    required this.time,
    this.image,
    this.locationUrl,
  });
}
