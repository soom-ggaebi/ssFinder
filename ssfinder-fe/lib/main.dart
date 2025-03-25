import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart'; // app.dart 파일을 가져옵니다.

Future main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  await Firebase.initializeApp();

  await Hive.initFlutter();
  // Box(Hive 데이터 저장소) 호출
  var locationBox = await Hive.openBox('locationBox');

  // FCM 권한 요청
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // 카카오 SDK 초기화 - 네이티브 앱 키로 변경 필요
  KakaoSdk.init(nativeAppKey: '36863fcc7a9f44ed78b659db8ab7b077');
  runApp(MyApp());
}
