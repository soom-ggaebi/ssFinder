import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sumsumfinder/config/environment_config.dart';
import 'dart:io';

class AiApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  Future<String?> _getAccessToken() async {
    final accountId = await _storage.read(key: 'current_account_id');
    if (accountId == null) return null;
    return await _storage.read(key: 'access_token_$accountId');
  }

  Future<Map<String, dynamic>> analyzeImage({required File image}) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('인증 토큰을 가져올 수 없습니다.');
      }

      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(image.path),
      });

      final response = await _dio.post(
        '${EnvironmentConfig.baseUrl}/api/aianalyze/image',
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token',
          },
        ),
        data: formData,
      );

      print('response: ${response.data}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        throw Exception(response.data['message'] ?? '유효하지 않은 이미지 파일입니다.');
      } else if (response.statusCode == 500) {
        throw Exception(response.data['message'] ?? '이미지 분석 중 오류가 발생했습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: '예상치 못한 상태 코드: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('이미지 분석 API 호출 중 오류 발생: $e');
      rethrow; // 발생한 에러를 상위로 전달합니다.
    }
  }
}
