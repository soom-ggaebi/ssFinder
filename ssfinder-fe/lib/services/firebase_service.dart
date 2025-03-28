import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final NotificationService _notificationService = NotificationService();

  Future<void> initialize() async {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _setupForegroundNotification();
  }

  Future<void> _setupForegroundNotification() async {
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;

      if (notification != null && android != null) {
        _notificationService.showNotification(
          id: notification.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
        );
      } else if (message.data.isNotEmpty) {
        _notificationService.showNotification(
          id: message.data.hashCode,
          title: message.data['title'] ?? '새 메시지',
          body: message.data['body'] ?? '새로운 메시지가 도착했습니다',
        );
      }
    });
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final notificationService = NotificationService();

  if (message.notification == null && message.data.isNotEmpty) {
    await notificationService.showNotification(
      id: message.data.hashCode,
      title: message.data['title'] ?? '새 메시지',
      body: message.data['body'] ?? '새로운 메시지가 도착했습니다',
    );
  }
}
