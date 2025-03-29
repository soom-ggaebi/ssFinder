import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'services/notification_service.dart';
import 'services/firebase_service.dart';
import 'services/location_service.dart';
import 'services/kakao_login_service.dart';
import 'app.dart';

Future<void> main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

  // 서비스 초기화
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Firebase 초기화
  await Firebase.initializeApp();
  final firebaseService = FirebaseService();
  await firebaseService.initialize();

  // FCM 권한 요청
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // 위치 서비스 초기화
  final locationService = LocationService();
  await locationService.initialize();

  // Android 13 이상: 알림 권한 요청
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

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

  // 자동 로그인 시도 (결과 출력을 위한 디버그 로그 추가)
  bool autoLoginResult = await kakaoLoginService.autoLogin();
  print('자동 로그인 결과: $autoLoginResult');

  runApp(MyApp());
}
