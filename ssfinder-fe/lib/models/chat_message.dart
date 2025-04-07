import 'dart:io';
import 'package:flutter/foundation.dart';

class ChatMessage extends ChangeNotifier {
  final String text;
  final bool isSent;
  final String time;
  final File? imageFile;
  final String? imageUrl;
  final String? locationUrl;
  final String type;
  String _status; // private로 변경
  String? messageId;

  String get status => _status;

  set status(String newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners(); // 상태 변경 시 알림
    }
  }

  ChatMessage({
    required this.text,
    required this.isSent,
    required this.time,
    this.imageFile,
    this.imageUrl,
    this.locationUrl,
    this.type = 'NORMAL',
    String status = 'UNREAD',
    this.messageId,
  }) : _status = status;
}
