import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/environment_config.dart';
import 'package:sumsumfinder/models/noti_model.dart';

class NotificationApiService {
  static final baseUrl = EnvironmentConfig.baseUrl;
  static const _secureStorage = FlutterSecureStorage();
  final Dio _dio = Dio();

  // 보안 저장소에서 토큰 가져오기
  static Future<String?> _getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  // 알림 데이터 가져오기 (GET)
  static Future<NotificationResponse> getNotifications({
    required String type,
    int page = 0,
    int size = 10,
    int? lastId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다');
      }

      final queryParams = {
        'type': type,
        'page': page.toString(),
        'size': size.toString(),
      };

      if (lastId != null) {
        queryParams['lastId'] = lastId.toString();
      }

      final uri = Uri.parse(
        '$baseUrl/api/notifications',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'Accept-Charset': 'utf-8',
        },
      );

      // 한국어 처리를 위한 UTF-8 디코딩
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 200) {
        return NotificationResponse.fromJson(json.decode(decodedBody));
      } else {
        // 에러 응답 파싱 시도
        try {
          return NotificationResponse.fromJson(json.decode(decodedBody));
        } catch (e) {
          throw Exception('API 응답 오류: $decodedBody');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // 알림 발송하기 (POST)
  Future<void> postNotification({
    required String type,
    required String weather,
  }) async {
    try {
      final accessToken = await _secureStorage.read(key: 'access_token');

      if (accessToken == null) {
        throw Exception('로그인이 필요합니다');
      }

      final response = await _dio.post(
        '$baseUrl/api/notifications',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
        data: jsonEncode({'type': type, 'weather': weather}),
      );

      if (response.statusCode == 200) {
        print('알림이 성공적으로 전송되었습니다');
      } else {
        print('알림 전송 실패. 상태 코드: ${response.statusCode}');
      }
    } catch (e) {
      print('알림 전송 중 오류 발생: $e');
      rethrow;
    }
  }
}
