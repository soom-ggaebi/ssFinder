import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart'; // app.dart 파일을 가져옵니다.
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'dart:async';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/screens/splash_screen.dart';

Future main() async {
  // 1. Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase 초기화
  await Firebase.initializeApp();

  // 3. 환경 변수 로드
  await dotenv.load(fileName: ".env");

  // FCM 권한 요청
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // 4. 카카오 SDK 초기화
  String kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  if (kakaoNativeAppKey.isEmpty) {
    throw Exception(
      "KAKAO_NATIVE_APP_KEY is missing in the environment variables",
    );
  }
  KakaoSdk.init(nativeAppKey: kakaoNativeAppKey);

  // 5. 카카오 로그인 서비스 초기화 및 자동 로그인 시도
  final kakaoLoginService = KakaoLoginService();
  // 주기적 토큰 갱신 설정
  kakaoLoginService.setupPeriodicTokenRefresh();

  // 자동 로그인 시도 (결과 출력을 위한 디버그 로그 추가)
  bool autoLoginResult = await kakaoLoginService.autoLogin();
  print('자동 로그인 결과: $autoLoginResult');

  runApp(MyApp());
}
