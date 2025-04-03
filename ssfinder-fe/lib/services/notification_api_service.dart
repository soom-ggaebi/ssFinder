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

  // API 호출 메서드 수정 - ALL 타입 지원
  static Future<NotificationResponse> getNotifications({
    String? type, // 타입을 필수에서 선택으로 변경
    int page = 0,
    int size = 10,
    int? lastId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다');
      }

      // 쿼리 파라미터 구성 - type이 제공되는 경우만 추가
      final queryParams = <String, String>{
        'page': page.toString(),
        'size': size.toString(),
      };

      if (type != null && type != 'ALL') {
        queryParams['type'] = type;
      }

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

  // 특정 타입의 알림 전체 삭제 메서드
  static Future<bool> deleteAllNotifications(String type) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다');
      }

      final uri = Uri.parse(
        '$baseUrl/api/notifications',
      ).replace(queryParameters: {'type': type});

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 성공: 204 No Content
      if (response.statusCode == 204) {
        return true;
      } else {
        print('전체 알림 삭제 실패: HTTP 상태 코드 ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('전체 알림 삭제 중 오류 발생: $e');
      return false;
    }
  }

  // 알림 삭제 메서드
  static Future<bool> deleteNotification(int notificationId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('로그인이 필요합니다');
      }

      final uri = Uri.parse('$baseUrl/api/notifications/$notificationId');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // 성공: 204 No Content
      if (response.statusCode == 204) {
        return true;
      }
      // 충돌: 409 Conflict (이미 삭제된 알림)
      else if (response.statusCode == 409) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final errorData = json.decode(decodedBody);
        print('알림 삭제 실패: ${errorData['error']['message']}');
        return false;
      }
      // 그 외 오류
      else {
        print('알림 삭제 실패: HTTP 상태 코드 ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('알림 삭제 중 오류 발생: $e');
      return false;
    }
  }
}
