import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart'; // app.dart 파일을 가져옵니다.

Future main() async {
  await dotenv.load();
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  // 카카오 SDK 초기화 - 네이티브 앱 키로 변경 필요
  KakaoSdk.init(nativeAppKey: '36863fcc7a9f44ed78b659db8ab7b077');
  runApp(MyApp());
}
