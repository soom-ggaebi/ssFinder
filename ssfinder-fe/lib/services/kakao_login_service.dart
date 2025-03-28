import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import './location_service.dart';

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
  String get _backendUrl =>
      dotenv.env['BACKEND_URL'] ?? 'https://ssfinder.site';

  // KakaoLoginService 클래스에 추가할 메서드들

  // 1. 앱 시작 시 호출할 자동 로그인 메서드
  Future<bool> autoLogin() async {
    try {
      print('자동 로그인 시도 중...');

      // 1. 저장된 토큰 확인
      final accessToken = await getAccessToken();
      final refreshToken = await getRefreshToken();

      if (accessToken == null || refreshToken == null) {
        print('저장된 토큰이 없습니다. 자동 로그인 불가');
        isLoggedIn.value = false;
        return false;
      }

      // 2. 토큰 유효성 확인 및 필요시 갱신
      final authenticated = await ensureAuthenticated();
      if (!authenticated) {
        print('토큰 갱신 실패. 다시 로그인이 필요합니다.');
        isLoggedIn.value = false;
        return false;
      }

      // 3. 사용자 정보 가져오기
      final userProfile = await getUserProfile();
      if (userProfile == null) {
        print('사용자 정보 조회 실패. 다시 로그인이 필요합니다.');
        isLoggedIn.value = false;
        return false;
      }

      // 4. 카카오 API 토큰 확인 (선택적)
      try {
        if (await AuthApi.instance.hasToken()) {
          await UserApi.instance.accessTokenInfo();
          await _getUserInfo();
        }
      } catch (e) {
        print('카카오 토큰 확인 중 오류: $e');
        // 카카오 토큰 오류가 있어도 백엔드 토큰이 유효하면 진행
      }

      print('자동 로그인 성공!');
      isLoggedIn.value = true;
      return true;
    } catch (e) {
      print('자동 로그인 중 오류 발생: $e');
      isLoggedIn.value = false;
      return false;
    }
  }

  // 2. 토큰 자동 갱신을 위한 요청 인터셉터
  Future<http.Response> authenticatedRequestWithAutoRefresh(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      // 1. 먼저 기존 토큰으로 요청 시도
      final response = await authenticatedRequest(method, endpoint, body: body);

      // 2. 401 Unauthorized 응답일 경우 토큰 갱신 후 재시도
      if (response.statusCode == 401) {
        print('인증 만료. 토큰 갱신 시도 중...');
        final refreshed = await refreshAccessToken();

        if (refreshed) {
          print('토큰 갱신 성공. 요청 재시도...');
          return await authenticatedRequest(method, endpoint, body: body);
        } else {
          print('토큰 갱신 실패. 로그인 필요.');
          throw Exception('인증 토큰 갱신 실패');
        }
      }

      return response;
    } catch (e) {
      print('인증 요청 중 오류: $e');
      rethrow;
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

      // 로그인 시도 전 로그 추가
      print('카카오 로그인 시도 시작');

      // 카카오톡 앱 설치 여부에 관계없이 항상 카카오 계정으로 로그인
      print('카카오 계정으로 로그인 시도');
      token = await UserApi.instance.loginWithKakaoAccount();
      print('카카오 계정으로 로그인 토큰 발급: ${token.accessToken}');

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
      print('사용 중인 백엔드 URL: ${dotenv.env['BACKEND_URL'] ?? ''}');
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

        // 인증 성공 시 로그인 상태를 true로 설정
        isLoggedIn.value = true;

        return responseData['data'];
      } else {
        print('백엔드 인증 실패: ${responseData['error']}');
        isLoggedIn.value = false; // 인증 실패 시 명시적으로 false 설정
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

  // 리프레시 토큰 가져오기
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: 'refresh_token');
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

  // ==================== 새로 추가된 기능 ====================

  // 1. 백엔드 로그아웃 API 호출
  Future<bool> logoutFromBackend() async {
    try {
      // 기존의 authenticatedRequest 메서드 활용
      final response = await authenticatedRequest('POST', '/api/auth/logout');

      print('백엔드 로그아웃 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 204) {
        // 로그아웃 성공 시 저장된 토큰 삭제
        await _clearTokens();
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
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'token_expiry');
    print('저장된 토큰 삭제 완료');
  }

  // 통합 로그아웃 프로세스 (카카오 로그아웃 + 백엔드 로그아웃)
  Future<bool> fullLogout() async {
    try {
      // 1. 백엔드 로그아웃 (토큰 무효화)
      final backendLogoutSuccess = await logoutFromBackend();

      // 2. 카카오 로그아웃 (백엔드 로그아웃 성공 여부와 관계없이 진행)
      await logout();

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

  // 2. 액세스 토큰 재발급 API
  Future<bool> refreshAccessToken() async {
    try {
      // 저장된 리프레시 토큰 가져오기
      final refreshToken = await getRefreshToken();

      if (refreshToken == null) {
        print('리프레시 토큰이 없습니다.');
        return false;
      }

      // 백엔드 API 호출
      final response = await http.post(
        Uri.parse('$_backendUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      print('토큰 재발급 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        // 응답 파싱
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true) {
          // 새 토큰 저장
          final accessToken = responseData['data']['access_token'];
          final newRefreshToken = responseData['data']['refresh_token'];

          // 기존 만료 시간 정보 가져오기 (없으면 1시간으로 기본 설정)
          final expiryStr = await _storage.read(key: 'token_expiry');
          final now = DateTime.now().millisecondsSinceEpoch;
          final expiresIn =
              expiryStr != null ? int.parse(expiryStr) - now : 3600000; // 1시간

          // 새 토큰 저장
          await _storage.write(key: 'access_token', value: accessToken);
          await _storage.write(key: 'refresh_token', value: newRefreshToken);

          print('액세스 토큰 재발급 성공');
          return true;
        } else {
          print('토큰 재발급 실패: ${responseData['error']}');
          return false;
        }
      } else if (response.statusCode == 401) {
        // 리프레시 토큰이 유효하지 않으면 저장된 토큰 삭제
        print('리프레시 토큰이 유효하지 않습니다. 다시 로그인이 필요합니다.');
        await _clearTokens();
        isLoggedIn.value = false;
        return false;
      } else {
        print('토큰 재발급 요청 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('토큰 재발급 중 오류 발생: $e');
      return false;
    }
  }

  // 3. 회원 정보 조회 API
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await authenticatedRequest('GET', '/api/users');

      print('회원 정보 조회 응답 상태 코드: ${response.statusCode}');

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
      // 액세스 토큰 유효성 확인
      final token = await getAccessToken();

      if (token == null) {
        print('액세스 토큰이 존재하지 않습니다. 로그인이 필요합니다.');
        return false;
      }

      // 토큰 만료 시간 확인
      final expiryStr = await _storage.read(key: 'token_expiry');

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
}
