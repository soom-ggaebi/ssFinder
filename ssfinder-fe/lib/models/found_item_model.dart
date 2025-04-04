import 'dart:io';

class FoundItemModel {
  final int id; // 물품의 고유 식별자
  final int? userId; // 물품을 등록한 사용자의 ID (null 가능)
  final File? image; // 물품 이미지 (null 가능)
  final String type; // 분실물 종류 (예: "경찰청")
  final String color; // 물품의 색상
  final String majorCategory; // 주요 카테고리
  final String minorCategory; // 세부 카테고리
  final String name; // 분실물 이름
  final String location; // 물품이 분실된 장소
  final String createdAt; // 등록(생성) 시간
  final String detail; // 물품에 대한 상세 설명
  final String foundAt; // 물품이 발견된 날짜 (예: "2025-03-25")
  final String status; // 물품 상태 (예: "STORED")
  final String? phone; // 연락처 (null 가능)
  final String? storedAt; // 보관 장소 (null 가능)
  final double latitude; // 분실 위치의 위도
  final double longitude; // 분실 위치의 경도
  final bool? bookmarked; // 즐겨찾기 여부 (null 가능)

  FoundItemModel({
    required this.id,
    required this.userId,
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

  factory FoundItemModel.fromJson(Map<String, dynamic> json) {
    final item = json['item'];
    return FoundItemModel(
      id: item['id'] as int,
      userId: item['user_id'] as int?, // null 가능
      image:
          item['image'] != null
              ? File(item['image'] as String)
              : null, // null 가능
      type: item['type'] as String,
      color: item['color'] as String,
      majorCategory: item['MajorCategory'] as String,
      minorCategory: item['MinorCategory'] as String,
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
  final File? image; // 이미지 파일 (null 가능)
  final String majorCategory; // 주요 카테고리 (문자열)
  final String minorCategory; // 세부 카테고리 (문자열)
  final String name; // 아이템 이름
  final String type; // 출처 (예: "숨숨파인더")
  final String? storageLocation; // 보관 위치 (예: "ㅇㅇ경찰청")
  final String foundLocation; // 분실된 위치 (예: "서울시 강남역 근처")
  final String createdTime; // 생성 시각

  FoundItemListModel({
    required this.id,
    this.image,
    required this.majorCategory,
    required this.minorCategory,
    required this.name,
    required this.type,
    required this.storageLocation,
    required this.foundLocation,
    required this.createdTime,
  });

  factory FoundItemListModel.fromJson(Map<String, dynamic> json) {
    return FoundItemListModel(
      id: json['id'] as int,
      image: json['image'] != null ? File(json['image'] as String) : null,
      majorCategory: json['MajorCategory'] as String,
      minorCategory: json['MinorCategory'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      storageLocation: json['storageLocation'] as String?,
      foundLocation: json['foundLocation'] as String,
      createdTime: json['createdTime'] as String,
    );
  }
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

  factory FoundItemCoordinatesModel.fromJson(Map<String, dynamic> json) {
    return FoundItemCoordinatesModel(
      id: json['id'] as int,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }
}
