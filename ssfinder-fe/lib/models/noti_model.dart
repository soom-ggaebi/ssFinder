import 'package:flutter/material.dart';

// 알림 유형 enum 정의
enum NotificationType { TRANSFER, CHAT, AI_MATCH, ITEM_REMINDER, ALL }

extension NotificationTypeExtension on NotificationType {
  String get apiValue {
    switch (this) {
      case NotificationType.TRANSFER:
        return 'TRANSFER';
      case NotificationType.CHAT:
        return 'CHAT';
      case NotificationType.AI_MATCH:
        return 'AI_MATCH';
      case NotificationType.ITEM_REMINDER:
        return 'ITEM_REMINDER';
      case NotificationType.ALL:
        return 'ALL';
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.TRANSFER:
        return '인계 알림';
      case NotificationType.CHAT:
        return '채팅 알림';
      case NotificationType.AI_MATCH:
        return 'AI 매칭 알림';
      case NotificationType.ITEM_REMINDER:
        return '소지품 알림';
      default:
        return '알림';
    }
  }

  String get defaultImagePath {
    switch (this) {
      case NotificationType.TRANSFER:
        return 'assets/images/chat/iphone_image.png';
      case NotificationType.CHAT:
        return 'assets/images/chat/profile_image.png';
      case NotificationType.AI_MATCH:
        return 'assets/images/chat/match_image.png';
      case NotificationType.ITEM_REMINDER:
        return 'assets/images/chat/wallet_image.png';
      default:
        return 'assets/images/chat/notification_default.png';
    }
  }
}

// API 응답 모델
class NotificationResponse {
  final bool success;
  final NotificationData? data;
  final ErrorData? error;
  final String timestamp;

  NotificationResponse({
    required this.success,
    this.data,
    this.error,
    required this.timestamp,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      success: json['success'],
      data:
          json['data'] != null ? NotificationData.fromJson(json['data']) : null,
      error: json['error'] != null ? ErrorData.fromJson(json['error']) : null,
      timestamp: json['timestamp'],
    );
  }
}

class NotificationData {
  final List<NotificationItem> content;
  final bool hasNext;

  NotificationData({required this.content, required this.hasNext});

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    return NotificationData(
      content:
          (json['content'] as List)
              .map((item) => NotificationItem.fromJson(item))
              .toList(),
      hasNext: json['hasNext'],
    );
  }
}

class ErrorData {
  final String code;
  final String message;

  ErrorData({required this.code, required this.message});

  factory ErrorData.fromJson(Map<String, dynamic> json) {
    return ErrorData(code: json['code'], message: json['message']);
  }
}

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final NotificationType type;
  final String sendAt;
  final bool isRead;
  final String? readAt;
  final String imagePath;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.sendAt,
    required this.isRead,
    this.readAt,
    String? imagePath,
  }) : imagePath = imagePath ?? type.defaultImagePath;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    NotificationType type;
    switch (json['type']) {
      case 'TRANSFER':
        type = NotificationType.TRANSFER;
        break;
      case 'CHAT':
        type = NotificationType.CHAT;
        break;
      case 'AI_MATCH':
        type = NotificationType.AI_MATCH;
        break;
      case 'ITEM_REMINDER':
        type = NotificationType.ITEM_REMINDER;
        break;
      default:
        type = NotificationType.ALL;
    }

    return NotificationItem(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: type,
      sendAt: json['send_at'],
      isRead: json['is_read'],
      readAt: json['read_at'],
    );
  }

  // 날짜 포맷팅 헬퍼 메서드
  String getFormattedDate() {
    try {
      final dateTime = DateTime.parse(sendAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return '방금 전';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}일 전';
      } else {
        return '${dateTime.year}.${dateTime.month}.${dateTime.day}';
      }
    } catch (e) {
      return sendAt;
    }
  }
}
