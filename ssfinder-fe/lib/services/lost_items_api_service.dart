import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sumsumfinder/config/environment_config.dart';
import 'package:sumsumfinder/models/found_items_model.dart';
import 'dart:io';

class LostItemsApiService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Future<String?> _getAccessToken() async {
    final accountId = await _storage.read(key: 'current_account_id');
    return await _storage.read(key: 'access_token_$accountId');
  }

  // 분실물 목록 조회
  Future<Map<String, dynamic>> getLostItems() async {
    try {
      final token = await _getAccessToken();
      print('token: ${token}');

      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/api/lost-items',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('분실물 목록을 찾을 수 없습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching lost items: $e');
      rethrow;
    }
  }

  // 분실물 등록
  Future<Map<String, dynamic>> postLostItem({
    required int itemCategoryId,
    required String title,
    required String color,
    required String lostAt,
    required String location,
    required String detail,
    required File? image,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _getAccessToken();

      final requestBody = FormData.fromMap({
        'itemCategoryId': itemCategoryId,
        'title': title,
        'color': color,
        'lostAt': lostAt,
        'location': location,
        'detail': detail,
        if (image != null) 'image': await MultipartFile.fromFile(image.path),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      });

      print('requestbody: ${requestBody.fields}');

      final response = await _dio.post(
        '${EnvironmentConfig.baseUrl}/api/lost-items',
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token',
          },
        ),
        data: requestBody,
      );

      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        throw Exception('필수 정보가 누락되었습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error posting lost item: $e');
      rethrow;
    }
  }

  // 분실물 상세 조회
  Future<Map<String, dynamic>> getLostItemDetail({required int lostId}) async {
    try {
      final token = await _getAccessToken();

      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/api/lost-items/$lostId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        print(response.data);
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('해당 분실물을 찾을 수 없습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching lost item detail: $e');
      rethrow;
    }
  }

  // 분실물 수정
  Future<Map<String, dynamic>> updateLostItem({
    required int lostId,
    required int itemCategoryId,
    required String title,
    required String color,
    required String lostAt,
    required String location,
    required String detail,
    File? image,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _getAccessToken();

      final requestBody = FormData.fromMap({
        'itemCategoryId': itemCategoryId.toString(),
        'title': title,
        'color': color,
        'lostAt': lostAt,
        'location': location,
        'detail': detail,
        if (image != null) 'image': await MultipartFile.fromFile(image.path),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      });

      final response = await _dio.put(
        '${EnvironmentConfig.baseUrl}/api/lost-items/$lostId',
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
            'Authorization': 'Bearer $token',
          },
        ),
        data: requestBody,
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        throw Exception('필수 정보가 누락되었습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating lost item: $e');
      rethrow;
    }
  }

  // 분실물 삭제
  Future<void> deleteLostItem({required int lostId}) async {
    try {
      final token = await _getAccessToken();

      final response = await _dio.delete(
        '${EnvironmentConfig.baseUrl}/api/lost-items/$lostId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode != 204) {
        throw Exception('삭제할 분실물을 찾을 수 없습니다.');
      }
    } catch (e) {
      print('Error deleting lost item: $e');
      rethrow;
    }
  }

  // 분실물 상태 변경
  Future<Map<String, dynamic>> updateLostItemStatus({
    required int lostId,
    required String status,
  }) async {
    try {
      final token = await _getAccessToken();

      final response = await _dio.put(
        '${EnvironmentConfig.baseUrl}/api/lost-items/$lostId/status',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
        data: {'status': status},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        throw Exception('상태 변경에 실패했습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating lost item status: $e');
      rethrow;
    }
  }

  Future<List<CategoryModel>> getCategories() async {
    try {
      final token = await _getAccessToken();

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/api/category',
        options: Options(headers: headers),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;
        final List<dynamic> categoriesJson = responseData['data'] as List<dynamic>;
        
        return categoriesJson
            .map((json) => CategoryModel.fromJson(json))
            .toList();
      } else if (response.statusCode == 404) {
        throw Exception('카테고리를 찾을 수 없습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }
}
