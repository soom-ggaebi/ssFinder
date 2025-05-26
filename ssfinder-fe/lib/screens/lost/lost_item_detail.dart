import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/lost_items_model.dart';
import 'package:sumsumfinder/services/lost_items_api_service.dart';
import '../../widgets/map_widget.dart';
import '../../widgets/lost/items_popup.dart';

class LostItemDetail extends StatefulWidget {
  final int itemId;
  final Function(int, String)? onStatusChanged;

  const LostItemDetail({
    Key? key,
    required this.itemId,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  _LostItemDetailState createState() => _LostItemDetailState();
}

class _LostItemDetailState extends State<LostItemDetail> {
  final LostItemsApiService _apiService = LostItemsApiService();
  LostItemModel? _item;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItemDetails();
  }

  Future<void> _loadItemDetails() async {
    try {
      final response = await _apiService.getLostItemDetail(
        lostId: widget.itemId,
      );
      setState(() {
        _item = LostItemModel.fromJson(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('상세 정보를 불러오는데 실패했습니다: $e')));
    }
  }

  Color getBackgroundColor(String colorName) {
    const colorMapping = [
      {'label': '검정색', 'color': Colors.black},
      {'label': '회색', 'color': Color(0xFFCCCCCC)},
      {'label': '베이지', 'color': Color(0xFFE6C9A8)},
      {'label': '갈색', 'color': Color(0xFFA67B5B)},
      {'label': '빨간색', 'color': Color(0xFFCE464B)},
      {'label': '주황색', 'color': Color(0xFFFFAD60)},
      {'label': '노란색', 'color': Color(0xFFFFDD65)},
      {'label': '초록색', 'color': Color(0xFF7FD17F)},
      {'label': '하늘색', 'color': Color(0xFF80CCFF)},
      {'label': '파란색', 'color': Color(0xFF5975FF)},
      {'label': '남색', 'color': Color(0xFF2B298D)},
      {'label': '보라색', 'color': Color(0xFFB771DF)},
      {'label': '분홍색', 'color': Color(0xFFFF9FC0)},
    ];

    for (final mapping in colorMapping) {
      if (colorName == mapping['label']) {
        return mapping['color'] as Color;
      }
    }
    return Colors.blue[100]!;
  }

  String extractLocation(String location) {
    List<String> parts = location.split(" ");
    if (parts.length >= 4) {
      return parts.sublist(1, 3).join(" ");
    }
    return location;
  }

  String extractLocation2(String location) {
    List<String> parts = location.split(" ");
    if (parts.length >= 4) {
      return parts.sublist(0, 3).join(" ");
    }
    return location;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            '분실 상세 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('분실 상세 정보')),
        body: Center(child: Text('정보를 불러올 수 없습니다.')),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, {'id': _item!.id, 'status': _item!.status});
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            '분실 상세 정보',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_horiz, color: Color(0xFF3D3D3D)),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder:
                      (context) => MainOptionsPopup(
                        item: _item!,
                        onUpdate: (updatedItem) {
                          setState(() => _item = updatedItem);
                        },
                      ),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // 이미지 영역
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      image:
                          _item!.image != null
                              ? DecorationImage(
                                image: NetworkImage(_item!.image!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        _item!.image == null
                            ? const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.white,
                            )
                            : null,
                  ),
                  // 상태 정보 표시
                  Positioned(
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            _item!.status == "LOST"
                                ? Colors.red[100]
                                : Colors.green[100],
                        borderRadius: BorderRadius.circular(50.0),
                      ),
                      child: Text(
                        _item!.status == "LOST" ? "숨은 물건" : "찾은 물건",
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              _item!.status == "LOST"
                                  ? Colors.red
                                  : Colors.green,
                        ),
                      ),
                    ),
                  ),
                  if (_item!.status != "LOST")
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // 색상 표시
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: getBackgroundColor(_item!.color),
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: Text(
                  _item!.color,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              // 카테고리 표시
              Text(
                (_item!.minorCategory == null)
                    ? "${_item!.majorCategory}"
                    : "${_item!.majorCategory} > ${_item!.minorCategory}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              // 이름 및 위치, 시간 표시
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _item!.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              extractLocation(_item!.location),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const Text(
                              ' · ',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _item!.createdAt.substring(0, 10),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 상세 설명
              Text(_item!.detail, style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              // 분실 일자 표시
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(50.0),
                ),
                child: const Text(
                  '분실 일자',
                  style: TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  _item!.lostAt,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              // 분실 장소 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Text(
                        '분실 장소',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => MapWidget(
                                    latitude: _item!.latitude,
                                    longitude: _item!.longitude,
                                  ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              extractLocation2(_item!.location),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // 지도 영역
              Container(
                height: 200,
                width: double.infinity,
                child: MapWidget(
                  latitude: _item!.latitude,
                  longitude: _item!.longitude,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
