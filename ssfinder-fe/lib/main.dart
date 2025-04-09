import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
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

// 전역 NavigatorKey 선언
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Flutter 엔진 초기화
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();

  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

  // 위치 서비스 초기화
  final locationService = LocationService();
  await locationService.initialize();

  // 알림 서비스 초기화 (NavigatorKey 추가)
  final notificationService = NotificationService();
  await notificationService.initialize(navigatorKey: navigatorKey);

  // 3. 로그인 상태 리스너 설정
  // notificationService.setupLoginStateListener();

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

  // 카카오 로그인 서비스 초기화
  final kakaoLoginService = KakaoLoginService();

  // 초기화 메소드 호출 (이 부분 추가)
  await kakaoLoginService.initializeAuth();

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

  // 로그인 상태 확인 및 강제 업데이트
  if (kakaoLoginService.isLoggedIn.value == false) {
    // 토큰이 있지만 로그인 상태가 아닌 경우 강제 로그인 시도
    bool forceLoginResult = await kakaoLoginService.forceLogin();
    print('강제 로그인 시도 결과: $forceLoginResult');
  }

  print('최종 로그인 상태: ${kakaoLoginService.isLoggedIn.value}');

  // 로그인 상태 변화 감지 및 위치 추적 제어
  kakaoLoginService.onLoginStatusChanged = (isLoggedIn) {
    print('로그인 상태 변경: $isLoggedIn');
    if (isLoggedIn) {
      locationService.startLocationService();
    } else {
      locationService.stopLocationService();
    }
  };

  // 현재 로그인 상태에 따른 위치 서비스 시작/중지
  if (kakaoLoginService.isLoggedIn.value) {
    await locationService.startLocationService();
  } else {
    await locationService.stopLocationService();
  }

  // 자동 로그인 시도 (결과 출력을 위한 디버그 로그 추가)
  bool autoLoginResult = await kakaoLoginService.autoLogin();
  print('자동 로그인 결과: $autoLoginResult');

  // 자동 로그인 결과에 따라 위치 추적 시작 또는 중지
  if (autoLoginResult) {
    await locationService.startLocationService();
  } else {
    await locationService.stopLocationService();
  }

  // navigatorKey를 MyApp에 전달
  runApp(MyApp(navigatorKey: navigatorKey));
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
