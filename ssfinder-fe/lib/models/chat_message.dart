import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ChatMessage extends ChangeNotifier {
  final String text;
  final bool isSent;
  final DateTime sentAt;
  final File? imageFile;
  final String? imageUrl;
  final String? locationUrl;
  final String type;
  String _status;
  final String? messageId;

  ChatMessage({
    required this.text,
    required this.isSent,
    required this.sentAt,
    this.imageFile,
    this.imageUrl,
    this.locationUrl,
    this.type = 'NORMAL',
    String status = 'UNREAD',
    this.messageId,
  }) : _status = status;

  String get status => _status;
  set status(String newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  /// UI 용으로 'HH:mm' 포맷된 문자열을 얻고 싶을 때
  String get time => DateFormat('HH:mm').format(sentAt);
}
