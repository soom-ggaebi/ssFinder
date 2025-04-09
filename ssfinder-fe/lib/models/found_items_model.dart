import 'package:google_maps_flutter/google_maps_flutter.dart';

class FoundItemModel {
  final int id;
  final int? userId;
  final String? userName;
  final String? image;
  final String type;
  final String color;
  final String? majorCategory;
  final String? minorCategory;
  final String name;
  final String location;
  final String createdAt;
  final String detail;
  final String foundAt;
  final String status;
  final String? phone;
  final String? storedAt;
  final double latitude;
  final double longitude;
  final bool? bookmarked;

  FoundItemModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.image,
    required this.type,
    required this.color,
    required this.majorCategory,
    required this.minorCategory,
    required this.name,
    required this.location,
    required this.createdAt,
    required this.detail,
    required this.foundAt,
    required this.status,
    this.phone,
    this.storedAt,
    required this.latitude,
    required this.longitude,
    this.bookmarked,
  });

  FoundItemModel copyWith({
    int? id,
    int? userId,
    String? userName,
    String? image,
    String? type,
    String? color,
    String? majorCategory,
    String? minorCategory,
    String? name,
    String? location,
    String? createdAt,
    String? detail,
    String? foundAt,
    String? status,
    String? phone,
    String? storedAt,
    double? latitude,
    double? longitude,
    bool? bookmarked,
  }) {
    return FoundItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      image: image ?? this.image,
      type: type ?? this.type,
      color: color ?? this.color,
      majorCategory: majorCategory ?? this.majorCategory,
      minorCategory: minorCategory ?? this.minorCategory,
      name: name ?? this.name,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      detail: detail ?? this.detail,
      foundAt: foundAt ?? this.foundAt,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      storedAt: storedAt ?? this.storedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      bookmarked: bookmarked ?? this.bookmarked,
    );
  }

  factory FoundItemModel.fromJson(Map<String, dynamic> json) {
    final item = json['data'];

    int id = int.parse(item['id']);
    int? userId = item['user_id'] != null ? int.parse(item['user_id']) : null;

    return FoundItemModel(
      id: id,
      userId: userId, // null 가능
      userName: item['userName'] as String?, // null 가능
      image: item['image'] as String?, // null 가능
      type: item['type'] as String,
      color: item['color'] as String,
      majorCategory: item['major_category'] as String?,
      minorCategory: item['minor_category'] as String?,
      name: item['name'] as String,
      location: item['location'] as String,
      createdAt: item['created_at'] as String,
      detail: item['detail'] as String,
      foundAt: item['found_at'] as String,
      status: item['status'] as String,
      phone: item['phone'] as String?, // null 가능
      storedAt: item['stored_at'] as String?, // null 가능
      latitude: (item['latitude'] as num).toDouble(),
      longitude: (item['longitude'] as num).toDouble(),
      bookmarked: item['bookmarked'] as bool?, // null 가능
    );
  }
}

class FoundItemListModel {
  final int id; // 아이템의 고유 ID
  final String? image; // 이미지 파일 (null 가능)
  final String? majorCategory; // 주요 카테고리
  final String? minorCategory; // 세부 카테고리
  final String name; // 아이템 이름
  final String type; // 출처
  final String status;
  final String? storageLocation; // 보관 위치
  final String foundLocation; // 분실된 위치
  final String createdTime; // 생성 시각
  final bool? bookmarked;

  FoundItemListModel({
    required this.id,
    this.image,
    required this.majorCategory,
    required this.minorCategory,
    required this.name,
    required this.type,
    required this.status,
    required this.storageLocation,
    required this.foundLocation,
    required this.createdTime,
    this.bookmarked,
  });

  FoundItemListModel copyWith({
    int? id,
    String? image,
    String? majorCategory,
    String? minorCategory,
    String? name,
    String? type,
    String? status,
    String? storageLocation,
    String? foundLocation,
    String? createdTime,
    bool? bookmarked,
  }) {
    return FoundItemListModel(
      id: id ?? this.id,
      image: image ?? this.image,
      majorCategory: majorCategory ?? this.majorCategory,
      minorCategory: minorCategory ?? this.minorCategory,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      storageLocation: storageLocation ?? this.storageLocation,
      foundLocation: foundLocation ?? this.foundLocation,
      createdTime: createdTime ?? this.createdTime,
      bookmarked: bookmarked ?? this.bookmarked,
    );
  }

  factory FoundItemListModel.fromJson(Map<String, dynamic> json) {
    return FoundItemListModel(
      id: json['id'] as int,
      image: json['image'] as String?,
      majorCategory: json['major_category'] as String?,
      minorCategory: json['minor_category'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      storageLocation: json['stored_at'] as String?,
      foundLocation: json['location'] as String,
      createdTime: json['created_at'] as String,
      bookmarked: json['bookmarked'] as bool?,
    );
  }
}

mixin ClusterItem {
  LatLng get location;
}

class FoundItemCoordinatesModel {
  final int id; // 아이템의 고유 식별자
  final double latitude; // 위도
  final double longitude; // 경도

  FoundItemCoordinatesModel({
    required this.id,
    required this.latitude,
    required this.longitude,
  });

  LatLng get location => LatLng(latitude, longitude);

  factory FoundItemCoordinatesModel.fromJson(Map<String, dynamic> json) {
    return FoundItemCoordinatesModel(
      id: json['id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}

class CategoryModel {
  final int id;
  final String name;
  final int? parentId;
  final String? parentName;

  CategoryModel({
    required this.id,
    required this.name,
    this.parentId,
    this.parentName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] as String,
      parentId: json['parent_id'] as int?,
      parentName: json['parent_name'] as String?,
    );
  }
}
