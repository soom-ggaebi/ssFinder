import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/notification_service.dart';
import 'services/firebase_service.dart';
import 'services/location_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  final locationService = LocationService();
  await locationService.initialize();

  // Android 13 이상: 알림 권한 요청
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  // 카카오 SDK 초기화
  KakaoSdk.init(nativeAppKey: '36863fcc7a9f44ed78b659db8ab7b077');

  runApp(MyApp());
}
