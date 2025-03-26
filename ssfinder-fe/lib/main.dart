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

  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // 4. 카카오 SDK 초기화
  String kakaoNativeAppKey = dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  if (kakaoNativeAppKey.isEmpty) {
    throw Exception(
      "KAKAO_NATIVE_APP_KEY is missing in the environment variables",
    );
  }
  KakaoSdk.init(nativeAppKey: kakaoNativeAppKey); // 환경변수에서 키를 사용

  runApp(MyApp());
}
