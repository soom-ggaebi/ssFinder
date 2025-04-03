import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/noti_model.dart';

class NotificationItemWidget extends StatelessWidget {
  final NotificationItem notification;

  const NotificationItemWidget({Key? key, required this.notification})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 알림 타입에 따른 하이라이트 여부
    final isHighlighted = notification.type == NotificationType.TRANSFER;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: notification.isRead ? Colors.white : const Color(0xFFE9F1FF),
        border: const Border(
          bottom: BorderSide(color: Color(0xFF4F4F4F), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제품 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              notification.imagePath,
              width: 95,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: Colors.grey[300],
                    child: const Icon(Icons.notifications, color: Colors.grey),
                  ),
            ),
          ),
          const SizedBox(width: 12),

          // 텍스트 내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 2),

                Text(notification.type.displayName),
                const SizedBox(height: 6),

                Text(
                  notification.body,
                  style: TextStyle(
                    color: isHighlighted ? Colors.red : const Color(0xFF3D3D3D),
                    fontWeight:
                        isHighlighted ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  notification.getFormattedDate(),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
