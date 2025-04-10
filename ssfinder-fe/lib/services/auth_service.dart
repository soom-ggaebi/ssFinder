import 'package:shared_preferences/shared_preferences.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';

class AuthService {
  static const String _jwtKey = 'jwt_token';
  static const String _userIdKey = 'user_id';
  static const String _userNicknameKey = 'user_nickname';

  // JWT 토큰 저장
  static Future<void> saveJwtToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jwtKey, token);
  }

  // JWT 토큰 가져오기
  static Future<String> getJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jwtKey) ?? '';
  }

  // 사용자 ID 저장
  static Future<bool> saveUserInfo() async {
    try {
      final kakaoLoginService = KakaoLoginService();
      final userProfile = await kakaoLoginService.getUserProfile();

      if (userProfile != null) {
        final prefs = await SharedPreferences.getInstance();

        // 사용자 ID 저장
        if (userProfile.containsKey('id')) {
          await prefs.setString(_userIdKey, userProfile['id'].toString());
        }

        // 닉네임 저장
        if (userProfile.containsKey('profile_nickname')) {
          await prefs.setString(
            _userNicknameKey,
            userProfile['profile_nickname'],
          );
        }

        // JWT 토큰 저장
        final token = await kakaoLoginService.getAccessToken();
        if (token != null) {
          await prefs.setString(_jwtKey, token);
        }

        return true;
      }
      return false;
    } catch (e) {
      print('사용자 정보 저장 중 오류 발생: $e');
      return false;
    }
  }

  // 사용자 ID 가져오기
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('_userIdKey') ?? '';
  }

  // 로그인 상태 확인
  static Future<bool> isLoggedIn() async {
    final jwt = await getJwtToken();
    return jwt.isNotEmpty;
  }

  // 로그아웃 (토큰 삭제)
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_jwtKey);
    await prefs.remove(_userIdKey);
  }
}
