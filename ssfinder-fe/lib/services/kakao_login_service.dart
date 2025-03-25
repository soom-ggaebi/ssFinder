import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class KakaoLoginService {
  // 싱글톤 패턴 구현
  static final KakaoLoginService _instance = KakaoLoginService._internal();

  factory KakaoLoginService() {
    return _instance;
  }

  KakaoLoginService._internal();

  // 로그인 상태를 관리하는 변수
  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  User? user;

  // 토큰 저장을 위한 secure storage
  final _storage = const FlutterSecureStorage();

  // 백엔드 URL 가져오기
  String get _backendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'https://ssfinder.site';

  // 로그인 시도 함수
  Future<bool> login() async {
    try {
      bool isInstalled = await isKakaoTalkInstalled();
      OAuthToken? token;

      // 로그인 시도 전 로그 추가
      print('카카오 로그인 시도 시작');

      if (isInstalled) {
        try {
          print('카카오톡 앱으로 로그인 시도');
          token = await UserApi.instance.loginWithKakaoTalk();
          print('카카오톡으로 로그인 토큰 발급: ${token.accessToken}');
        } catch (e) {
          print('카카오톡 로그인 실패 상세: $e');

          // 앱 로그인 실패 시 계정으로 로그인 시도
          print('카카오 계정으로 로그인으로 전환');
          token = await UserApi.instance.loginWithKakaoAccount();
          print('카카오 계정으로 로그인 토큰 발급: ${token.accessToken}');
        }
      } else {
        print('카카오톡 앱 미설치, 카카오 계정으로 로그인');
        token = await UserApi.instance.loginWithKakaoAccount();
        print('카카오 계정으로 로그인 토큰 발급: ${token.accessToken}');
      }

      // 사용자 정보 가져오기
      await _getUserInfo();
      return true;
    } catch (e) {
      print('카카오 로그인 실패 최종: $e');
      if (e is PlatformException) {
        print('PlatformException 세부 정보: ${e.code}, ${e.message}, ${e.details}');
      }
      return false;
    }
  }

  // 사용자 정보 가져오기
  Future<void> _getUserInfo() async {
    try {
      user = await UserApi.instance.me();
      isLoggedIn.value = true;
      print('사용자 정보 요청 성공: ${user?.kakaoAccount?.profile?.nickname}');
    } catch (e) {
      print('사용자 정보 요청 실패: $e');
    }
  }

  // 로그아웃 함수
  Future<void> logout() async {
    try {
      await UserApi.instance.logout();
      isLoggedIn.value = false;
      user = null;
      print('로그아웃 성공');
    } catch (e) {
      print('로그아웃 실패: $e');
    }
  }

  // 현재 로그인 상태 확인
  Future<void> checkLoginStatus() async {
    try {
      if (await AuthApi.instance.hasToken()) {
        try {
          // 토큰 유효성 검사
          await UserApi.instance.accessTokenInfo();
          // 토큰 유효함
          await _getUserInfo();
        } catch (e) {
          // 토큰 만료 등의 이유로 오류 발생
          print('토큰 오류: $e');
          isLoggedIn.value = false;
        }
      } else {
        isLoggedIn.value = false;
      }
    } catch (e) {
      print('로그인 상태 확인 실패: $e');
    }
  }

  // 백엔드 서버에 카카오 로그인 정보 전송
  Future<Map<String, dynamic>?> authenticateWithBackend() async {
    if (user == null) {
      print('사용자 정보가 없습니다. 먼저 로그인해주세요.');
      return null;
    }

    try {
      // fcm 토큰 가져오기
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // 성별 정보 변환 (male/female)
      String? gender;
      if (user!.kakaoAccount?.gender == Gender.male) {
        gender = "male";
      } else if (user!.kakaoAccount?.gender == Gender.female) {
        gender = "female";
      }

      // 백엔드 요청 데이터 준비
      final requestData = {
        'name': user!.kakaoAccount?.name ?? "",
        'profile_nickname': user!.kakaoAccount?.profile?.nickname ?? "",
        'email': user!.kakaoAccount?.email ?? "",
        'birthyear': user!.kakaoAccount?.birthyear ?? "",
        'birthday': user!.kakaoAccount?.birthday ?? "",
        'gender': gender,
        'provider_id': user!.id.toString(),
        'phone_number': user!.kakaoAccount?.phoneNumber ?? "",
        'fcm_token': fcmToken,
      };

      print('백엔드 인증 요청 데이터: $requestData');

      // 백엔드 API 호출
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );
      print(
        '사용 중인 백엔드 URL: ${dotenv.env['BACKEND_URL'] ?? 'http://localhost:8080'}',
      );
      print('백엔드 응답 상태 코드: ${response.statusCode}');

      // 응답 파싱
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        print('백엔드 인증 성공: ${responseData['data']['result_type']}');

        // 토큰 저장
        await _saveTokens(
          responseData['data']['access_token'],
          responseData['data']['refresh_token'],
          responseData['data']['expires_in'],
        );

        return responseData['data'];
      } else {
        print('백엔드 인증 실패: ${responseData['error']}');
        return null;
      }
    } catch (e) {
      print('백엔드 연동 중 오류 발생: $e');
      return null;
    }
  }

  // 토큰 저장
  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    int expiresIn,
  ) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(
      key: 'token_expiry',
      value: (DateTime.now().millisecondsSinceEpoch + expiresIn).toString(),
    );
    print('토큰 저장 완료');
  }

  // 액세스 토큰 가져오기
  Future<String?> getAccessToken() async {
    return await _storage.read(key: 'access_token');
  }

  // 토큰으로 인증된 API 호출 헬퍼 함수
  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await getAccessToken();
    final url = Uri.parse('$_backendUrl$endpoint');

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    switch (method.toUpperCase()) {
      case 'GET':
        return http.get(url, headers: headers);
      case 'POST':
        return http.post(url, headers: headers, body: jsonEncode(body));
      case 'PUT':
        return http.put(url, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return http.delete(url, headers: headers);
      default:
        throw Exception('지원하지 않는 HTTP 메소드');
    }
  }

  // 통합 로그인 프로세스
  Future<bool> loginWithBackendAuth() async {
    try {
      // 1. 카카오 로그인
      final kakaoLoginSuccess = await login();
      if (!kakaoLoginSuccess) {
        print('카카오 로그인 실패');
        return false;
      }

      // 2. 백엔드 인증
      final authResult = await authenticateWithBackend();
      if (authResult == null) {
        print('백엔드 인증 실패');
        return false;
      }

      print('로그인 및 백엔드 인증 완료: ${authResult['result_type']}');
      return true;
    } catch (e) {
      print('로그인 프로세스 중 오류 발생: $e');
      return false;
    }
  }
}
