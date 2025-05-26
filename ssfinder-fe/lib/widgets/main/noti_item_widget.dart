import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/noti_model.dart';
import 'package:sumsumfinder/utils/time_formatter.dart';

// onTap 콜백 추가 (외부에서 탭 이벤트 처리를 받기 위함)
typedef NotificationTapCallback = void Function(NotificationItem notification);

class NotificationItemWidget extends StatelessWidget {
  final NotificationItem notification;
  final Function(NotificationItem)? onDelete;
  final NotificationTapCallback? onTap; // 탭 콜백 추가

  const NotificationItemWidget({
    Key? key,
    required this.notification,
    this.onDelete,
    this.onTap, // 외부에서 탭 이벤트 처리 받기
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 알림 타입에 따른 하이라이트 여부
    final isHighlighted = notification.type == NotificationType.TRANSFER;

    // Dismissible 위젯으로 감싸서 스와이프 삭제 추가
    return Dismissible(
      key: Key('notification-${notification.id}'),
      direction: DismissDirection.endToStart, // 오른쪽에서 왼쪽으로 스와이프
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('알림 삭제'),
              content: const Text('이 알림을 삭제하시겠습니까?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('삭제'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) {
        // 삭제 콜백 호출
        if (onDelete != null) {
          onDelete!(notification);
        }
      },
      child: GestureDetector(
        onTap: () {
          print(
            'NotificationItemWidget: Tap detected on ${notification.id}, type: ${notification.type}',
          );
          // 외부에서 제공된 탭 콜백 사용
          if (onTap != null) {
            onTap!(notification);
          }
        },
        child: Container(
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
                        child: const Icon(
                          Icons.notifications,
                          color: Colors.grey,
                        ),
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
                        color:
                            isHighlighted
                                ? Colors.red
                                : const Color(0xFF3D3D3D),
                        fontWeight:
                            isHighlighted ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      TimeFormatter.getFormattedDate(notification.sendAt),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
