import 'dart:io';

class ChatMessage {
  final String text;
  final bool isSent; // true면 보낸 메시지, false면 받은 메시지
  final String time;
  final File? imageFile; // 로컬 이미지 파일
  final String? imageUrl; // 원격 이미지 URL
  final String? locationUrl; // 위치 메시지 지원 (옵션)
  final String type; // 메시지 타입 (NORMAL, IMAGE, LOCATION)

  ChatMessage({
    required this.text,
    required this.isSent,
    required this.time,
    this.imageFile,
    this.imageUrl,
    this.locationUrl,
    this.type = 'NORMAL',
  });
}
