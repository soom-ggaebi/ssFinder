import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _jwtKey = 'jwt_token';
  static const String _userIdKey = 'user_id';

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
  static Future<void> saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // 사용자 ID 가져오기
  static Future<String> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey) ?? '';
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
