import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:sumsumfinder/config/environment_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' show min; // 파일 상단에 추가

class KakaoLoginService {
  // 싱글톤 패턴 구현
  static final KakaoLoginService _instance = KakaoLoginService._internal();

  factory KakaoLoginService() {
    return _instance;
  }

  KakaoLoginService._internal() {
    // isLoggedIn 값이 변경될 때마다 onLoginStatusChanged 콜백 호출
    isLoggedIn.addListener(() {
      if (onLoginStatusChanged != null) {
        onLoginStatusChanged!(isLoggedIn.value);
      }
    });
  }

  // 로그인 상태를 관리하는 변수
  final ValueNotifier<bool> isLoggedIn = ValueNotifier<bool>(false);
  User? user;

  // 로그인 상태 변화 콜백 (true: 로그인, false: 로그아웃)
  void Function(bool)? onLoginStatusChanged;

  // 토큰 저장을 위한 secure storage
  final _storage = const FlutterSecureStorage();

  // 백엔드 URL 가져오기
  // String get _backendUrl => dotenv.env['BACKEND_URL'] ?? '';
  String _backendUrl = EnvironmentConfig.baseUrl;

  // KakaoLoginService 클래스에 추가할 메서드들

  // 1. autoLogin() 함수를 간소화하고 더 명확하게 만들기
  // 자동 로그인 단일 메서드로 통합
  Future<bool> autoLogin() async {
    // 1. 저장된 토큰 확인
    final accountId = await _storage.read(key: 'current_account_id');
    if (accountId == null) return false;

    final accessToken = await _storage.read(key: 'access_token_$accountId');
    final refreshToken = await _storage.read(key: 'refresh_token_$accountId');
    if (accessToken == null || refreshToken == null) return false;

    // 2. 토큰 만료 확인 및 갱신
    final expiryStr = await _storage.read(key: 'token_expiry_$accountId');
    if (expiryStr != null) {
      final expiry = int.parse(expiryStr);
      final now = DateTime.now().millisecondsSinceEpoch;

      if (expiry - now < 300000) {
        // 5분 이내 만료
        final refreshed = await refreshAccessToken();
        if (!refreshed) return false;
      }
    }

    // 3. 사용자 정보 확인
    try {
      final userProfile = await getUserProfile();
      if (userProfile == null) return false;

      // 4. 카카오 토큰 확인 (선택적)
      try {
        if (await AuthApi.instance.hasToken()) {
          await UserApi.instance.accessTokenInfo();
          await _getUserInfo();
        }
      } catch (e) {
        // 카카오 토큰 오류는 무시 (백엔드 토큰이 있으면 충분)
      }

      isLoggedIn.value = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  // 2. 토큰 자동 갱신을 위한 요청 인터셉터
  // HTTP 요청 인터셉터 개선
  Future<http.Response> authenticatedRequestWithAutoRefresh(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    // 요청 전 토큰 유효성 검사
    final isAuthenticated = await ensureAuthenticated();
    if (!isAuthenticated) {
      throw Exception('인증 실패');
    }

    final response = await authenticatedRequest(method, endpoint, body: body);

    // 401 응답 처리
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        return await authenticatedRequest(method, endpoint, body: body);
      } else {
        isLoggedIn.value = false;
        throw Exception('인증 토큰 갱신 실패');
      }
    }

    return response;
  }

  // KakaoLoginService.dart 내부에 다음 메서드 추가
  Future<bool> forceLogin() async {
    // 토큰이 있는지 확인
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      return false;
    }

    try {
      // 사용자 정보 가져오기 시도
      final userProfile = await getUserProfile();
      if (userProfile == null) {
        return false;
      }

      // 로그인 상태 강제 설정
      isLoggedIn.value = true;
      print('강제 로그인 성공: ${userProfile['profile_nickname']}');
      return true;
    } catch (e) {
      print('강제 로그인 중 오류: $e');
      return false;
    }
  }

  // 3. 주기적 토큰 유효성 검사 및 갱신 (백그라운드에서 실행)
  Future<void> setupPeriodicTokenRefresh() async {
    // 30분마다 토큰 유효성 확인 및 필요시 갱신
    Timer.periodic(const Duration(minutes: 30), (timer) async {
      if (isLoggedIn.value) {
        print('주기적 토큰 유효성 검사 실행...');

        final authenticated = await ensureAuthenticated();
        if (!authenticated) {
          print('토큰 갱신 실패. 로그인 상태 해제.');
          isLoggedIn.value = false;
          // 여기서 로그인 화면으로 이동하는 이벤트를 발생시킬 수 있음
        } else {
          print('토큰 유효성 확인 완료');
        }
      }
    });
  }

  // 로그인 시도 함수
  Future<bool> login() async {
    try {
      bool isInstalled = await isKakaoTalkInstalled();
      OAuthToken? token;

      print('카카오 로그인 시도 시작');
      token = await UserApi.instance.loginWithKakaoAccount();
      print('카카오 계정으로 로그인 토큰 발급: ${token.accessToken}');

      // 사용자 정보 가져오기
      await _getUserInfo();

      // 현재 계정 ID 저장
      if (user != null) {
        await _storage.write(
          key: 'current_account_id',
          value: user!.id.toString(),
        );
        print('현재 계정 ID 업데이트: ${user!.id}');
      }

      return true;
    } catch (e) {
      print('카카오 로그인 실패: $e');
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
      print('사용자 정보 요청 성공: ${user?.kakaoAccount?.profile?.nickname}');

      // 백엔드 토큰 출력 전에 토큰이 저장되었는지 확인
      final jwtToken = await getAccessToken();
      print('백엔드 JWT 토큰: $jwtToken');

      // 토큰이 null인 경우 백엔드 인증을 시도
      if (jwtToken == null && user != null) {
        print('JWT 토큰이 없습니다. 백엔드 인증을 시도합니다.');
        await authenticateWithBackend();

        // 인증 후 다시 토큰 확인
        final newToken = await getAccessToken();
        print('인증 후 JWT 토큰: $newToken');
      }
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
      // 기존 토큰 확인
      final existingAccessToken = await getAccessToken();
      final existingRefreshToken = await getRefreshToken();

      // 기존 토큰이 있다면 유효성 검증
      if (existingAccessToken != null && existingRefreshToken != null) {
        // 1. 토큰 만료 시간 확인
        bool isValid = await ensureAuthenticated();

        // 2. 토큰이 유효한 경우 실제 API 호출로 확인
        if (isValid) {
          try {
            // 사용자 정보 API를 호출하여 실제 토큰 유효성 확인
            final testResponse = await authenticatedRequest(
              'GET',
              '/api/users',
            );

            if (testResponse.statusCode == 200) {
              print('기존 토큰이 유효합니다. 새로운 토큰을 발급하지 않고 기존 토큰 사용');
              isLoggedIn.value = true;
              return {
                'access_token': existingAccessToken,
                'refresh_token': existingRefreshToken,
                'result_type': '기존 토큰 유지',
              };
            } else if (testResponse.statusCode == 401) {
              print('토큰이 만료되었습니다. 갱신 시도하겠습니다.');
              // 토큰 갱신 시도
              final refreshSuccess = await refreshAccessToken();
              if (refreshSuccess) {
                final newAccessToken = await getAccessToken();
                final newRefreshToken = await getRefreshToken();
                if (newAccessToken != null && newRefreshToken != null) {
                  print('토큰 갱신 성공. 갱신된 토큰 사용');
                  isLoggedIn.value = true;
                  return {
                    'access_token': newAccessToken,
                    'refresh_token': newRefreshToken,
                    'result_type': '토큰 갱신',
                  };
                }
              }
            }
          } catch (e) {
            print('토큰 유효성 검증 중 오류 발생: $e');
            // 오류 발생 시 새 토큰 발급으로 진행
          }
        }
      }

      print('새로운 토큰 발급 시도');

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
      print('사용 중인 백엔드 URL: $_backendUrl');
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

        // 추가 디버그: 저장 직후 토큰 확인 - 여기서 문제가 있음
        final accountId = user!.id.toString();
        final storedToken = await _storage.read(key: 'access_token_$accountId');
        print('저장 후 access_token_$accountId: $storedToken');

        // 사용자 닉네임 SharedPreferences에 저장
        final prefs = await SharedPreferences.getInstance();
        final nickname = user?.kakaoAccount?.profile?.nickname ?? "";
        if (nickname.isNotEmpty) {
          await prefs.setString('user_nickname', nickname);
          print('닉네임 저장됨: $nickname');
        }

        // 인증 성공 시 로그인 상태를 true로 설정
        isLoggedIn.value = true;

        return responseData['data'];
      } else {
        print('백엔드 인증 실패: ${responseData['error']}');
        isLoggedIn.value = false;
        return null;
      }
    } catch (e) {
      print('백엔드 연동 중 오류 발생: $e');
      return null;
    }
  }

  // 2. 계정 ID 관리 일관성 유지
  // 토큰 저장 메서드 개선
  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    int expiresIn,
  ) async {
    final accountId = user?.id.toString() ?? '';
    if (accountId.isEmpty) {
      throw Exception('사용자 ID가 없습니다.');
    }

    final expiryTime = DateTime.now().millisecondsSinceEpoch + expiresIn;

    // 계정별 토큰만 저장하고 현재 계정 ID를 기록
    await _storage.write(key: 'access_token_$accountId', value: accessToken);
    await _storage.write(key: 'refresh_token_$accountId', value: refreshToken);
    await _storage.write(
      key: 'token_expiry_$accountId',
      value: expiryTime.toString(),
    );
    await _storage.write(key: 'current_account_id', value: accountId);
  }

  // 토큰 접근 단순화
  Future<String?> getAccessToken() async {
    final accountId = await _storage.read(key: 'current_account_id');
    if (accountId == null) return null;
    return await _storage.read(key: 'access_token_$accountId');
  }

  Future<String?> getRefreshToken() async {
    try {
      // 현재 카카오 계정이 있는 경우 해당 계정 ID 사용
      if (user != null) {
        String accountId = user!.id.toString();
        return await _storage.read(key: 'refresh_token_$accountId');
      }

      // 현재 저장된 계정 ID 확인
      String? currentAccountId = await _storage.read(key: 'current_account_id');
      if (currentAccountId == null) {
        print('저장된 계정 ID가 없습니다');
        return null;
      }

      return await _storage.read(key: 'refresh_token_$currentAccountId');
    } catch (e) {
      print('리프레시 토큰 조회 중 오류: $e');
      return null;
    }
  }

  Future<void> debugTokenStorage() async {
    final currentAccountId = await _storage.read(key: 'current_account_id');
    print('==== 토큰 저장소 디버깅 ====');
    print('현재 계정 ID: $currentAccountId');

    // 모든 저장된 키 출력
    final allKeys = await _storage.readAll();
    for (var entry in allKeys.entries) {
      // 토큰 값은 일부만 표시
      final value =
          entry.key.contains('token') && entry.value.isNotEmpty
              ? '${entry.value.substring(0, min(15, entry.value.length))}...'
              : entry.value;
      print('${entry.key}: $value');
    }

    // 현재 사용 중인 토큰 확인
    final activeToken = await getAccessToken();
    if (activeToken != null) {
      print(
        '현재 활성 토큰: ${activeToken.substring(0, min(15, activeToken.length))}...',
      );
    } else {
      print('현재 활성 토큰: null');
    }

    print('=============================');
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

      // JWT 토큰 출력 (이 부분을 수정)
      final jwtToken = await getAccessToken();
      print('백엔드 JWT 토큰: $jwtToken');

      // 토큰이 null인지 명시적으로 확인
      if (jwtToken == null) {
        print('로그인 후에도 JWT 토큰이 null입니다. 토큰 저장 로직을 확인하세요.');
        return false;
      }
      // 로그인 성공 후 디버깅
      await debugTokenStorage();

      print('로그인 및 백엔드 인증 완료: ${authResult['result_type']}');
      return true;
    } catch (e) {
      print('로그인 프로세스 중 오류 발생: $e');
      return false;
    }
  }

  // 3. _saveTokens() 메서======= 새로 추가된 기능 ====================

  // 1. 백엔드 로그아웃 API 호출
  Future<bool> logoutFromBackend() async {
    try {
      // 기존의 authenticatedRequest 메서드 활용
      final response = await authenticatedRequest('POST', '/api/auth/logout');

      print('백엔드 로그아웃 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 204) {
        // 로그아웃 성공 시 저장된 토큰 삭제
        // await _clearTokens();
        return true;
      } else {
        print('백엔드 로그아웃 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('백엔드 로그아웃 중 오류 발생: $e');
      return false;
    }
  }

  // 토큰 삭제 메서드
  Future<void> _clearTokens() async {
    try {
      // 현재 계정 ID 가져오기
      String? accountId = await _storage.read(key: 'current_account_id');

      if (accountId != null) {
        // 해당 계정의 토큰만 삭제
        await _storage.delete(key: 'access_token_$accountId');
        await _storage.delete(key: 'refresh_token_$accountId');
        await _storage.delete(key: 'token_expiry_$accountId');
        print('계정 ID $accountId의 토큰 삭제 완료');
      }

      // 현재 계정 정보도 삭제
      await _storage.delete(key: 'current_account_id');
    } catch (e) {
      print('토큰 삭제 중 오류 발생: $e');
    }
  }

  // 통합 로그아웃 프로세스 (카카오 로그아웃 + 백엔드 로그아웃)
  Future<bool> fullLogout() async {
    try {
      // 1. 백엔드 로그아웃 (토큰 무효화)
      final backendLogoutSuccess = await logoutFromBackend();

      // 2. 카카오 로그아웃 (백엔드 로그아웃 성공 여부와 관계없이 진행)
      await logout();

      // 로그인 상태 false로 변경
      isLoggedIn.value = false;
      user = null;

      // 백엔드 로그아웃 결과 반환
      return backendLogoutSuccess;
    } catch (e) {
      print('통합 로그아웃 프로세스 중 오류 발생: $e');
      // 에러가 발생해도 카카오 로그아웃은 시도
      try {
        await logout();
      } catch (kakaoError) {
        print('카카오 로그아웃 중 오류 발생: $kakaoError');
      }
      return false;
    }
  }

  // 오류 처리 유틸리티 메서드 추가
  void _handleAuthError(dynamic error) {
    isLoggedIn.value = false;
    // 적절한 에러 핸들링 로직 (예: 이벤트 버스를 통한 알림)
  }

  // refreshAccessToken() 오류 처리 개선
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          await _saveTokens(
            responseData['data']['access_token'],
            responseData['data']['refresh_token'],
            responseData['data']['expires_in'] ?? 3600000,
          );
          // 토큰 갱신 후 디버깅
          await debugTokenStorage();
          return true;
        }
      }

      // 실패 시 인증 상태 초기화
      if (response.statusCode == 401 || response.statusCode == 400) {
        await _clearTokens();
        isLoggedIn.value = false;
      }

      return false;
    } catch (e) {
      await _clearTokens();
      isLoggedIn.value = false;
      return false;
    }
  }

  // 3. initializeAuth() 메소드 개선하여 앱 시작 시 자동 로그인 시도
  Future<void> initializeAuth() async {
    try {
      print('인증 초기화 시작...');

      // 현재 계정 ID 확인
      final accountId = await _storage.read(key: 'current_account_id');
      if (accountId == null) {
        print('저장된 계정 ID가 없습니다. 로그인이 필요합니다.');
        return;
      }

      // 계정별 토큰 확인
      final accessToken = await _storage.read(key: 'access_token_$accountId');
      if (accessToken == null) {
        print('저장된 액세스 토큰이 없습니다. 로그인이 필요합니다.');
        return;
      }

      print('저장된 액세스 토큰이 있습니다. 자동 로그인 시도...');

      // 토큰 만료 시간 확인
      final expiryStr = await _storage.read(key: 'token_expiry_$accountId');
      if (expiryStr != null) {
        final expiry = int.parse(expiryStr);
        final now = DateTime.now().millisecondsSinceEpoch;

        // 토큰이 만료되었거나 곧 만료될 예정인 경우
        if (expiry - now < 300000) {
          print('토큰이 만료되었거나 곧 만료됩니다. 갱신 시도...');
          await refreshAccessToken();
        }
      }

      // 백엔드 API로 사용자 정보 조회 시도
      final userProfile = await getUserProfile();
      if (userProfile != null) {
        print('사용자 정보 조회 성공. 자동 로그인 완료!');
        isLoggedIn.value = true;
      } else {
        print('사용자 정보 조회 실패. 자동 로그인 불가');
      }

      // 주기적 토큰 갱신 설정
      setupPeriodicTokenRefresh();

      print('인증 초기화 완료');
    } catch (e) {
      print('인증 초기화 중 오류 발생: $e');
    }
  }

  // 추가: 이전 토큰 형식 삭제
  Future<void> cleanupOldTokenFormat() async {
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'token_expiry');
      print('이전 토큰 형식 삭제 완료');
    } catch (e) {
      print('이전 토큰 형식 삭제 중 오류: $e');
    }
  }

  // 3. 회원 정보 조회 API
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      print('회원 정보 조회 시도...');
      print('사용 중인 백엔드 URL: $_backendUrl');

      final token = await getAccessToken();
      print('요청에 사용될 토큰: ${token?.substring(0, 15)}...');

      final response = await authenticatedRequest('GET', '/api/users');

      print('회원 정보 조회 응답 상태 코드: ${response.statusCode}');
      final String decodedBody = utf8.decode(response.bodyBytes);
      debugPrint('회원 정보 조회 응답 본문: $decodedBody');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          print('회원 정보 조회 성공');
          return responseData['data'];
        } else {
          print('회원 정보 조회 실패: ${responseData['error']}');
          return null;
        }
      } else if (response.statusCode == 401) {
        // 토큰이 만료되었을 가능성이 있으므로 토큰 재발급 시도
        print('인증 토큰이 만료되었습니다. 토큰 재발급 시도...');
        final refreshSuccess = await refreshAccessToken();

        if (refreshSuccess) {
          // 토큰 재발급 성공 시 다시 회원 정보 조회 시도
          return await getUserProfile();
        } else {
          print('토큰 재발급 실패. 다시 로그인이 필요합니다.');
          return null;
        }
      } else {
        print('회원 정보 조회 요청 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('회원 정보 조회 중 오류 발생: $e');
      return null;
    }
  }

  // 4. 회원 정보 수정 API
  Future<Map<String, dynamic>?> updateUserProfile({
    String? name,
    String? nickname,
    String? birth,
    String? phone,
  }) async {
    try {
      // 요청 본문 구성 (null이 아닌 필드만 포함)
      final Map<String, dynamic> requestBody = {};

      if (name != null) requestBody['name'] = name;
      if (nickname != null) requestBody['nickname'] = nickname;
      if (birth != null) requestBody['birth'] = birth;
      if (phone != null) requestBody['phone'] = phone;

      // 수정할 데이터가 없으면 종료
      if (requestBody.isEmpty) {
        print('수정할 정보가 없습니다.');
        return null;
      }

      final response = await authenticatedRequest(
        'PUT',
        '/api/users',
        body: requestBody,
      );

      print('회원 정보 수정 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          print('회원 정보 수정 성공');
          return responseData['data'];
        } else {
          print('회원 정보 수정 실패: ${responseData['error']}');
          return null;
        }
      } else if (response.statusCode == 401) {
        // 토큰이 만료되었을 가능성이 있으므로 토큰 재발급 시도
        print('인증 토큰이 만료되었습니다. 토큰 재발급 시도...');
        final refreshSuccess = await refreshAccessToken();

        if (refreshSuccess) {
          // 토큰 재발급 성공 시 다시 회원 정보 수정 시도
          return await updateUserProfile(
            name: name,
            nickname: nickname,
            birth: birth,
            phone: phone,
          );
        } else {
          print('토큰 재발급 실패. 다시 로그인이 필요합니다.');
          return null;
        }
      } else {
        print('회원 정보 수정 요청 실패: ${response.statusCode}, ${response.body}');
        return null;
      }
    } catch (e) {
      print('회원 정보 수정 중 오류 발생: $e');
      return null;
    }
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

  // 회원 탈퇴 API
  Future<bool> deleteAccount() async {
    try {
      final response = await authenticatedRequest('DELETE', '/api/users');

      print('회원 탈퇴 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('회원 탈퇴 성공: ${responseData['data']['message']}');
        } else {
          print('회원 탈퇴 성공');
        }

        // 카카오 연결 끊기
        try {
          await UserApi.instance.unlink();
          print('카카오 연결 끊기 성공');
        } catch (e) {
          print('카카오 연결 끊기 실패: $e');
          // 카카오 연결 끊기 실패해도 회원 탈퇴는 진행
        }

        // 저장된 토큰 삭제
        await _clearTokens();
        isLoggedIn.value = false;
        user = null;

        return true;
      } else if (response.statusCode == 401) {
        print('인증 토큰이 만료되었습니다. 토큰 재발급 시도...');
        final refreshSuccess = await refreshAccessToken();

        if (refreshSuccess) {
          return await deleteAccount();
        } else {
          print('토큰 재발급 실패. 다시 로그인이 필요합니다.');
          // 로그인 페이지로 강제 이동하는 로직 추가 필요
          await _clearTokens();
          isLoggedIn.value = false;
          user = null;
          throw Exception('토큰 재발급 실패');
        }
      } else {
        final errorMessage =
            response.body.isNotEmpty
                ? 'HTTP ${response.statusCode}: ${response.body}'
                : '회원 탈퇴 요청 실패: ${response.statusCode}';
        print(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('회원 탈퇴 중 오류 발생: $e');
      throw Exception('회원 탈퇴 중 오류 발생: $e');
    }
  }

  // 6. 토큰 인증 확인 및 필요 시 갱신하는 유틸리티 메서드
  Future<bool> ensureAuthenticated() async {
    try {
      // 현재 계정 ID 가져오기
      String? accountId =
          user?.id.toString() ?? await _storage.read(key: 'current_account_id');

      if (accountId == null) {
        print('계정 ID가 없습니다. 로그인이 필요합니다.');
        return false;
      }

      // 액세스 토큰 유효성 확인
      final token = await getAccessToken();

      if (token == null) {
        print('액세스 토큰이 존재하지 않습니다. 로그인이 필요합니다.');
        return false;
      }

      // 토큰 만료 시간 확인
      final expiryStr = await _storage.read(key: 'token_expiry_$accountId');

      if (expiryStr != null) {
        final expiry = int.parse(expiryStr);
        final now = DateTime.now().millisecondsSinceEpoch;

        // 토큰이 만료되었거나 곧 만료될 예정인 경우 (5분 이내)
        if (expiry - now < 300000) {
          // 5분 = 300,000 밀리초
          print('토큰이 곧 만료되거나 이미 만료되었습니다. 갱신 시도...');
          return await refreshAccessToken();
        }
      }

      return true;
    } catch (e) {
      print('인증 확인 중 오류 발생: $e');
      return false;
    }
  }

  Future<bool> deleteFcmToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) {
        print('FCM 토큰이 없습니다.');
        return true;
      }

      final token = await getAccessToken();
      if (token == null) {
        print('액세스 토큰을 가져올 수 없습니다.');
        return false;
      }

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final url = Uri.parse('$_backendUrl/api/notifications/token');

      final response = await http.delete(
        url,
        headers: headers,
        body: jsonEncode({'token': fcmToken}),
      );

      print('FCM 토큰 삭제 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('FCM 토큰 삭제 성공');
        return true;
      } else {
        print('FCM 토큰 삭제 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('FCM 토큰 삭제 중 오류 발생: $e');
      return false;
    }
  }
}
