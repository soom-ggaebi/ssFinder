import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // 샘플 알림 데이터
  final List<NotificationItem> notifications = [
    NotificationItem(
      title: '휴대폰 > 아이폰',
      subtitle: '아이폰 16 틸',
      message: '인계 가능한 날이 하루 남았습니다!',
      dateTime: '제9조 (습득자의 권리 상실)에 의거함',
      imagePath: 'assets/images/chat/iphone_image.png',
      isHighlighted: true,
    ),
    NotificationItem(
      title: '휴대폰 > 아이폰',
      subtitle: '아이폰 16 틸',
      message: '오늘까지 인계 가능합니다!',
      dateTime: '제9조 (습득자의 권리 상실)에 의거함',
      imagePath: 'assets/images/chat/iphone_image.png',
      isHighlighted: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('알림 메시지'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Color(0xFF4F4F4F), height: 1.0),
        ),
      ),
      body:
          notifications.isEmpty
              ? const Center(
                child: Text(
                  '알림이 없습니다',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
              : ListView.separated(
                itemCount: notifications.length,
                separatorBuilder:
                    (context, index) =>
                        Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  return NotificationItemWidget(
                    notification: notifications[index],
                  );
                },
              ),
    );
  }
}

class NotificationItem {
  final String title;
  final String subtitle;
  final String message;
  final String dateTime;
  final String imagePath;
  final bool isHighlighted;

  NotificationItem({
    required this.title,
    required this.subtitle,
    required this.message,
    required this.dateTime,
    required this.imagePath,
    this.isHighlighted = false,
  });
}

class NotificationItemWidget extends StatelessWidget {
  final NotificationItem notification;

  const NotificationItemWidget({Key? key, required this.notification})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFE9F1FF),
        border: Border(bottom: BorderSide(color: Color(0xFF4F4F4F), width: 1)),
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
                    child: const Icon(Icons.phone_iphone, color: Colors.grey),
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
                Text(notification.subtitle),
                const SizedBox(height: 6),
                Text(
                  notification.message,
                  style: TextStyle(
                    color:
                        notification.isHighlighted
                            ? Colors.red
                            : Color(0xFF3D3D3D),
                    fontWeight:
                        notification.isHighlighted
                            ? FontWeight.w500
                            : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.dateTime,
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
