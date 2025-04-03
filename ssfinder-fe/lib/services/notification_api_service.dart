import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sumsumfinder/config/environment_config.dart';
import 'dart:convert';

class NotificationApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  Future<void> postNotification({
    required String type,
    required String weather,
  }) async {
    try {
      final accessToken = await _storage.read(key: 'access_token');

      final response = await _dio.post(
        '${EnvironmentConfig.baseUrl}/api/notifications',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        ),
        data: jsonEncode({'type': type, 'weather': weather}),
      );

      if (response.statusCode == 200) {
        print('Notification sent successfully');
      } else {
        print(
          'Failed to send notification. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
}
