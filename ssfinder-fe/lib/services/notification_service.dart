import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import './location_service.dart';
import './weather_service.dart';
import './notification_api_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  GlobalKey<NavigatorState>? _navigatorKey;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    _navigatorKey = navigatorKey;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // 알림을 탭했을 때 알림 페이지로 이동
        _navigateToNotificationPage(response.payload);
      },
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // 알림 페이지로 이동하는 메서드
  void _navigateToNotificationPage(String? payload) {
    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.pushNamed('/notifications');
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          icon: 'ic_notification',
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showWeatherNotification() async {
    try {
      String weather;

      // LocationService 인스턴스 가져오기
      final locationService = LocationService();

      // 현재 위치 가져오기
      final position = await locationService.getCurrentPosition();

      // 날씨 정보 가져오기
      final weatherData = await WeatherService.getWeather(
        position.latitude,
        position.longitude,
      );

      final notificationService = NotificationApiService();

      final type = "ITEM_REMINDER";
      final weatherId = weatherData['weather'][0]['id'];

      if (weatherId >= 500 && weatherId <= 531) {
        weather = 'RAIN';
      } else if (weatherId >= 600 && weatherId <= 622) {
        weather = 'SNOW';
      } else if ([731, 751, 761].contains(weatherId)) {
        weather = 'DUSTY';
      } else {
        weather = 'DEFAULT';
      }

      notificationService.postNotification(type: type, weather: weather);
    } catch (e) {
      print('날씨 정보를 가져오는 데 실패했습니다: $e');
    }
  }
}
