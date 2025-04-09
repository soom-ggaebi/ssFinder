import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvironmentConfig {
  static String get baseUrl => dotenv.env['BACKEND_URL'] ?? '';
  static String get weatherApiKey => dotenv.env['WEATHER_API_KEY'] ?? '';
  static String get weatherBaseUrl => dotenv.env['WEATHER_BASE_URL'] ?? '';
  static String get kakaoNativeAppKey =>
      dotenv.env['KAKAO_NATIVE_APP_KEY'] ?? '';
  static String get googleMapApiKey =>
      dotenv.env['GOOGLE_MAP_API_KEY'] ?? '';
  static String get kakaoApiKey =>
      dotenv.env['KAKAO_API_KEY'] ?? '';
}
