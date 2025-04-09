class LostItemModel {
  final int id; // 물품의 고유 식별자
  final int? userId; // 물품을 등록한 사용자의 ID (null 가능)
  final String? image; // 물품 이미지 URL (null 가능)
  final String color; // 물품의 색상
  final String? majorCategory; // 주요 카테고리
  final String? minorCategory; // 세부 카테고리
  final String title; // 분실물 제목
  final String detail; // 물품에 대한 상세 설명
  final String lostAt; // 물품이 분실된 날짜 (예: "2025-03-24")
  final String location; // 물품이 분실된 장소
  final String status; // 물품 상태 (예: "LOST")
  final String createdAt; // 등록(생성) 시간
  final String updatedAt; // 수정 시간
  final double latitude; // 분실 위치의 위도
  final double longitude; // 분실 위치의 경도
  final bool notificationEnabled; // 알림

  LostItemModel({
    required this.id,
    this.userId,
    this.image,
    required this.color,
    required this.majorCategory,
    required this.minorCategory,
    required this.title,
    required this.detail,
    required this.lostAt,
    required this.location,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.latitude,
    required this.longitude,
    required this.notificationEnabled,
  });

  LostItemModel copyWith({
    int? id,
    int? userId,
    String? image,
    String? color,
    String? majorCategory,
    String? minorCategory,
    String? title,
    String? detail,
    String? lostAt,
    String? location,
    String? status,
    String? createdAt,
    String? updatedAt,
    double? latitude,
    double? longitude,
    bool? notificationEnabled,
  }) {
    return LostItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      image: image ?? this.image,
      color: color ?? this.color,
      majorCategory: majorCategory ?? this.majorCategory,
      minorCategory: minorCategory ?? this.minorCategory,
      title: title ?? this.title,
      detail: detail ?? this.detail,
      lostAt: lostAt ?? this.lostAt,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }

  factory LostItemModel.fromJson(Map<String, dynamic> json) {
    final item = json['data'];
    return LostItemModel(
      id: item['id'] as int,
      userId: item['user_id'] as int?,
      image: item['image'] as String?,
      color: item['color'] as String,
      majorCategory: item['major_item_category'] as String?,
      minorCategory: item['minor_item_category'] as String?,
      title: item['title'] as String,
      detail: item['detail'] as String,
      lostAt: item['lost_at'] as String,
      location: item['location'] as String,
      status: item['status'] as String,
      createdAt: item['created_at'] as String,
      updatedAt: item['updated_at'] as String,
      latitude: (item['latitude'] as num).toDouble(),
      longitude: (item['longitude'] as num).toDouble(),
      notificationEnabled: (item['notification_enabled']) as bool,
    );
  }
}

class LostItemListModel {
  final int id; // 아이템의 고유 ID
  final int? userId; // 사용자 ID (null 가능)
  final String color; // 색상
  final String? majorCategory; // 주요 카테고리
  final String? minorCategory; // 세부 카테고리
  final String title; // 분실물 제목
  final String lostAt; // 분실 날짜
  final String? image; // 이미지 URL (null 가능)
  final String status; // 상태 (예: "LOST")

  LostItemListModel({
    required this.id,
    this.userId,
    required this.color,
    required this.majorCategory,
    required this.minorCategory,
    required this.title,
    required this.lostAt,
    this.image,
    required this.status,
  });

  LostItemListModel copyWith({
    int? id,
    int? userId,
    String? color,
    String? majorCategory,
    String? minorCategory,
    String? title,
    String? lostAt,
    String? image,
    String? status,
  }) {
    return LostItemListModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      color: color ?? this.color,
      majorCategory: majorCategory ?? this.majorCategory,
      minorCategory: minorCategory ?? this.minorCategory,
      title: title ?? this.title,
      lostAt: lostAt ?? this.lostAt,
      image: image ?? this.image,
      status: status ?? this.status,
    );
  }

  factory LostItemListModel.fromJson(Map<String, dynamic> json) {
    return LostItemListModel(
      id: json['id'] as int,
      userId: json['user_id'] as int?,
      color: json['color'] as String,
      majorCategory: json['major_item_category'] as String?,
      minorCategory: json['minor_item_category'] as String?,
      title: json['title'] as String,
      lostAt: json['lost_at'] as String,
      image: json['image'] as String?,
      status: json['status'] as String,
    );
  }
}
