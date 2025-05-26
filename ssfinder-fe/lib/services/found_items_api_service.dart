import 'package:dio/dio.dart';
import '../models/found_items_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sumsumfinder/config/environment_config.dart';
import 'dart:io';

class FoundItemsApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  Future<String?> _getAccessToken() async {
    final accountId = await _storage.read(key: 'current_account_id');
    return await _storage.read(key: 'access_token_$accountId');
  }

  // 습득물 등록
  Future<Map<String, dynamic>> postFoundItem({
    required int itemCategoryId,
    required String name,
    required String foundAt,
    required String location,
    required String color,
    required File? image,
    String? detail,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _getAccessToken();

      final requestBody = FormData.fromMap({
        'itemCategoryId': itemCategoryId,
        'name': name,
        'foundAt': foundAt,
        'location': location,
        'color': color,
        'latitude': latitude,
        'longitude': longitude,
        'detail': detail ?? '',
        if (image != null) 'image': await MultipartFile.fromFile(image.path),
      });

      print('#### FormData fields: ${requestBody.fields}');

      final response = await _dio.post(
        '${EnvironmentConfig.baseUrl}/api/found-items',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: requestBody,
      );

      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error sending location data: $e');
      rethrow;
    }
  }

  // 습득물 상세 조회
  Future<Map<String, dynamic>> getFoundItemDetail({
    required int foundId,
  }) async {
    try {
      final token = await _getAccessToken();

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/api/found-items/$foundId',
        options: Options(headers: headers),
        queryParameters: {'foundId': foundId.toString()},
      );

      print('response: ${response}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('해당 습득물을 찾을 수 없습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching item detail: $e');
      rethrow;
    }
  }

  // 습득물 수정
  Future<Map<String, dynamic>> updateFoundItem({
    required int foundId,
    required int itemCategoryId,
    required String name,
    required String foundAt,
    required String location,
    required String color,
    File? image,
    String? detail,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _getAccessToken();

      final requestBody = FormData.fromMap({
        'itemCategoryId': itemCategoryId,
        'name': name,
        'foundAt': foundAt,
        'location': location,
        'color': color,
        if (image != null) 'image': await MultipartFile.fromFile(image.path),
        'detail': detail ?? '',
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      });

      print('#### FormData fields 수정: ${requestBody.fields}');

      final response = await _dio.put(
        '${EnvironmentConfig.baseUrl}/api/found-items/$foundId',
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
      print('Error updating found item: $e');
      rethrow;
    }
  }

  // 습득물 삭제
  Future<Map<String, dynamic>> deleteFoundItem({required int foundId}) async {
    try {
      final token = await _getAccessToken();

      final response = await _dio.delete(
        '${EnvironmentConfig.baseUrl}/api/found-items/$foundId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 204) {
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('삭제할 습득물을 찾을 수 없습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error deleting found item: $e');
      rethrow;
    }
  }

  // 습득물 상태 변경
  Future<Map<String, dynamic>> updateFoundItemStatus({
    required int foundId,
    required String status,
  }) async {
    try {
      final token = await _getAccessToken();

      final response = await _dio.put(
        '${EnvironmentConfig.baseUrl}/api/found-items/$foundId/status',
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
      } else if (response.statusCode == 404) {
        throw Exception('해당 카테고리의 습득물을 찾을 수 없습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error updating item status: $e');
      rethrow;
    }
  }

  // 내 습득물 목록 조회
  Future<Map<String, dynamic>> getMyFoundItems() async {
    try {
      final token = await _getAccessToken();

      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/api/found-items/my-items',
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
        throw Exception('유효한 인증 토큰이 필요합니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching my found items: $e');
      rethrow;
    }
  }

  // 북마크 등록
  Future<void> bookmarkFoundItem({required int foundId}) async {
    try {
      final token = await _getAccessToken();

      final response = await _dio.post(
        '${EnvironmentConfig.baseUrl}/api/found-items/$foundId/bookmark',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 201) {
        print('북마크 성공');
      } else if (response.statusCode == 401) {
        throw Exception('유효한 인증 토큰이 필요합니다.');
      } else if (response.statusCode == 409) {
        throw Exception('이미 북마크된 습득물입니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error bookmarking found item: $e');
      rethrow;
    }
  }

  // 북마크 삭제
  Future<void> deleteBookmark({required int foundId}) async {
    try {
      final token = await _getAccessToken();

      final response = await _dio.delete(
        '${EnvironmentConfig.baseUrl}/api/found-items/$foundId/bookmark',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 204) {
        print('북마크 삭제 성공');
      } else if (response.statusCode == 401) {
        throw Exception('유효한 인증 토큰이 필요합니다.');
      } else if (response.statusCode == 404) {
        throw Exception('북마크가 존재하지 않습니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error deleting bookmark: $e');
      rethrow;
    }
  }

  // 북마크 목록 조회
  Future<Map<String, dynamic>> getBookmarks() async {
    try {
      final token = await _getAccessToken();

      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/api/found-items/bookmarks',
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
        throw Exception('유효한 인증 토큰이 필요합니다.');
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching bookmarks: $e');
      rethrow;
    }
  }

  // 습득물 좌표 조회
  Future<List<FoundItemCoordinatesModel>> getFilteredFoundItems({
    required double maxLat,
    required double maxLng,
    required double minLat,
    required double minLng,
    String? status,
    String? type,
    String? foundAt,
    String? majorCategory,
    String? minorCategory,
    String? color,
  }) async {
    try {
      final token = await _getAccessToken();

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final requestBody = {
        'max_latitude': maxLat,
        'max_longitude': maxLng,
        'min_latitude': minLat,
        'min_longitude': minLng,
        'status': status,
        'type': type,
        if (foundAt != '') 'found_at': foundAt,
        if (majorCategory != '') 'major_category': majorCategory,
        if (minorCategory != '') 'minor_category': minorCategory,
        if (color != '') 'color': color,
      };

      print('getFilteredFoundItems: ${requestBody}');

      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/api/found-items/filter',
        options: Options(headers: headers),
        data: requestBody,
      );

      if (response.statusCode == 200) {
        final List<dynamic> itemsJson = response.data['data'] as List<dynamic>;
        return itemsJson
            .map((json) => FoundItemCoordinatesModel.fromJson(json))
            .toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching filtered found items: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getClusterDetailItems({
    required List<int> ids,
    required int page,
    int size = 10,
    String sortBy = 'createdAt',
    String sortDirection = 'desc',
  }) async {
    try {
      final token = await _getAccessToken();
      print('Access token: $token');

      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final requestBody = {'ids': ids};
      print(requestBody);

      final response = await _dio.get(
        '${EnvironmentConfig.baseUrl}/api/found-items/cluster/detail',
        options: Options(headers: headers),
        data: requestBody,
        queryParameters: {
          'page': page.toString(),
          'size': size.toString(),
          'sortBy': sortBy,
          'sortDirection': sortDirection,
        },
      );

      if (response.statusCode == 200) {
        print(response.data);
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;
        final List<dynamic> itemsJson =
            responseData['data']['content'] as List<dynamic>;

        final items =
            itemsJson
                .map((json) {
                  try {
                    return FoundItemListModel.fromJson(json);
                  } catch (e) {
                    print('Error parsing item: $e');
                    return null;
                  }
                })
                .where((item) => item != null)
                .cast<FoundItemListModel>()
                .toList();
        return {
          'items': items,
          'totalPages': responseData['data']['totalPages'] ?? 1,
          'totalElements': responseData['data']['totalElements'] ?? 0,
          'currentPage': responseData['data']['pageable']?['pageNumber'] ?? 0,
          'isLastPage': responseData['data']['last'] ?? true,
        };
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Unexpected status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching cluster detail items: $e');
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
        final Map<String, dynamic> responseData =
            response.data as Map<String, dynamic>;
        final List<dynamic> categoriesJson =
            responseData['data'] as List<dynamic>;

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
