import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sumsumfinder/config/environment_config.dart';

class LocationApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  Future<void> sendLocationData(List<Map<String, dynamic>> route) async {
    try {
      final accessToken = await _storage.read(key: 'access_token');

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
}
