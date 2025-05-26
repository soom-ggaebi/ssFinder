import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sumsumfinder/config/environment_config.dart';

class LocationApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  Future<String?> _getAccessToken() async {
    final accountId = await _storage.read(key: 'current_account_id');
    return await _storage.read(key: 'access_token_$accountId');
  }

  Future<void> sendLocationData(List<Map<String, dynamic>> route) async {
    try {
      final accessToken = await _getAccessToken();

      final requestBody = {
        "event_type": "move30",
        "event_timestamp": DateTime.now().toUtc().toIso8601String(),
        "route": route,
      };
      print(requestBody);

      final response = await _dio.post(
        '${EnvironmentConfig.baseUrl}/api/users/routes',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
        data: requestBody,
      );

      if (response.statusCode == 201) {
        print('Location data sent successfully.');
      } else {
        print(
          'Failed to send location data. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error sending location data: $e');
    }
  }

  Future<Map<String, dynamic>> getLocationRoutes(String date) async {
    try {
      final accessToken = await _getAccessToken();

      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/api/users/routes',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
        queryParameters: {"date": date},
      );

      if (response.statusCode == 200) {
        print('Location data retrieved successfully.');
        return response.data;
      } else {
        print('Failed to retrieve location data. Status code: ${response.statusCode}');
        return response.data;
      }
    } catch (e) {
      print('Error retrieving location data: $e');
      throw e; // 호출 측에서 에러를 처리할 수 있도록 예외를 다시 던집니다.
    }
  }
}
