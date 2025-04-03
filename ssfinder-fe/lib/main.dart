import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'services/notification_service.dart';
import 'services/firebase_service.dart';
import 'services/location_service.dart';
import 'services/kakao_login_service.dart';
import 'app.dart';

Future<void> main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

  // 위치 서비스 초기화
  final locationService = LocationService();
  await locationService.initialize();

  // 알림 서비스 초기화
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Firebase 초기화
  await Firebase.initializeApp();
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // 권한 요청

  await _requestPermissions();

  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // 카카오 SDK 초기화 - .env에서 키를 불러옴
  String kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  if (kakaoNativeAppKey.isEmpty) {
    throw Exception(
      "KAKAO_NATIVE_APP_KEY is missing in the environment variables",
    );
  }
  KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);

  // 카카오 로그인 서비스 초기화 및 자동 로그인 시도
  final kakaoLoginService = KakaoLoginService();
  // 주기적 토큰 갱신 설정
  kakaoLoginService.setupPeriodicTokenRefresh();

  // 로그인 상태 변화 감지 및 위치 추적 제어
  kakaoLoginService.onLoginStatusChanged = (isLoggedIn) {
    if (isLoggedIn) {
      locationService.startLocationService();
    } else {
      locationService.stopLocationService();
    }
  };

  // 자동 로그인 시도 (결과 출력을 위한 디버그 로그 추가)
  bool autoLoginResult = await kakaoLoginService.autoLogin();
  print('자동 로그인 결과: $autoLoginResult');

  // 자동 로그인 결과에 따라 위치 추적 시작 또는 중지
  if (autoLoginResult) {
    await locationService.startLocationService();
  } else {
    await locationService.stopLocationService();
  }

  runApp(MyApp());
}

Future<void> _requestPermissions() async {
  // 알림 권한 요청 (Android 13 이상 포함)
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  // 위치 권한 요청
  if (await Permission.location.isDenied) {
    await Permission.location.request();
  }
}
