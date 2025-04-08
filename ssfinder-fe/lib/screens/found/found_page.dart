import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'found_map.dart';
import 'found_items_list.dart';
import 'found_item_filter.dart';
import 'found_item_form.dart';
import 'package:sumsumfinder/models/found_items_model.dart';
import 'package:sumsumfinder/services/found_items_api_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FoundPage extends StatefulWidget {
  FoundPage({Key? key}) : super(key: key);

  @override
  _FoundPageState createState() => _FoundPageState();
}

class _FoundPageState extends State<FoundPage> {
  Position? _currentPosition;
  String _searchQuery = "";

  // API에서 받아온 습득물 데이터와 로딩 상태 변수
  List<FoundItemCoordinatesModel> foundItems = [];
  bool isLoading = true;

  GoogleMapController? _mapController;

  // 필터 파라미터: 기본값은 필터를 적용하지 않은 상태
  // 이제 카테고리는 majorCategory와 minorCategory로 분리하여 저장함
  Map<String, dynamic> _filterParams = {
    'status': 'All',
    'type': '전체',
    'foundAt': '',
    'majorCategory': '',
    'minorCategory': '',
    'color': '',
  };

  @override
  void initState() {
    super.initState();
    _getLocationData();
  }

  // 위치 데이터를 가져온 후 FoundItems 목록 로딩
  Future<void> _getLocationData() async {
    try {
      Position pos = await getLocationData();
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
        _loadFoundItems();
      }
    } catch (e) {
      print('위치 권한 없음: $e');
      if (mounted) {
        setState(() {
          _currentPosition = Position(
            latitude: 35.160121, // 기본 위치 (예: FoundMap.companyLatLng 위도)
            longitude: 126.851317, // 기본 위치 (예: FoundMap.companyLatLng 경도)
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        });
        _loadFoundItems();
      }
    }
  }

  /// 주소 검색: 입력된 텍스트를 좌표로 변환하여 현재 위치 업데이트
  Future<void> _searchAddress() async {
    if (_searchQuery.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(_searchQuery);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        setState(() {
          _currentPosition = Position(
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('주소 검색에 실패했습니다.')));
    }
  }

  /// 카테고리 문자열 분리 함수
  /// "A > B" 형식이면 A는 majorCategory, B는 minorCategory로 반환
  Map<String, String> _splitCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return {'majorCategory': 'null', 'minorCategory': 'null'};
    }
    final parts = category.split(' > ');
    if (parts.length >= 2) {
      return {
        'majorCategory': parts[0].trim(),
        'minorCategory': parts[1].trim(),
      };
    } else {
      return {'majorCategory': category.trim(), 'minorCategory': 'null'};
    }
  }

  /// API를 호출하여 습득물 데이터를 가져오는 함수
  /// 지도 영역 좌표와 함께 필터 파라미터(majorCategory, minorCategory 등)를 전달합니다.
  Future<void> _loadFoundItems() async {
    if (_mapController == null || !mounted) return;

    try {
      final bounds = await _mapController!.getVisibleRegion();
      final items = await FoundItemsApiService().getFoundItemCoordinates(
        maxLat: bounds.northeast.latitude,
        maxLng: bounds.northeast.longitude,
        minLat: bounds.southwest.latitude,
        minLng: bounds.southwest.longitude,
        status: _filterParams['status'],
        type: _filterParams['type'],
        foundAt: _filterParams['foundAt'],
        // API에 majorCategory와 minorCategory를 전달 (서비스 메서드도 이에 맞게 수정)
        majorCategory: _filterParams['majorCategory'],
        minorCategory: _filterParams['minorCategory'],
        color: _filterParams['color'],
      );

      if (mounted) {
        setState(() {
          foundItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('데이터 로딩에 실패했습니다.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FoundMap(
            latitude: _currentPosition?.latitude ?? 35.160121, // 기본 위치 (광주)
            longitude: _currentPosition?.longitude ?? 126.851317, // 기본 위치 (광주)
            onMapCreated: (controller) {
              _mapController = controller;
              _loadFoundItems();
            },
            onCameraIdle: _loadFoundItems,
            foundItems: foundItems,
            onClusterTap: (List<int> itemIds) {
              // 클러스터 탭 시 필요한 동작 구현 (없으면 생략)
            },
          ),
          // 하단 목록 영역: 로딩 상태에 따라 처리
          isLoading
              ? Center(child: CircularProgressIndicator())
              : FoundItemsList(
                itemIds: foundItems.map((item) => item.id).toList(),
              ),
          // 검색창 및 필터 버튼 영역
          Positioned(
            top: 48,
            left: 16,
            right: 80,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchAddress,
                    ),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: '위치 검색',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: () async {
                        // 현재 _filterParams 값을 전달합니다.
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    FilterPage(initialFilter: _filterParams),
                          ),
                        );
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            // FilterPage에서 반환한 값으로 필터 파라미터 업데이트
                            // 반환되는 값은 { 'state': ..., 'foundDate': ..., 'category': ..., 'color': ... }
                            _filterParams['status'] = result['state'] ?? 'All';
                            _filterParams['foundDate'] =
                                result['foundDate'] ?? 'null';
                            final categoryMap = _splitCategory(
                              result['category'],
                            );
                            _filterParams['majorCategory'] =
                                categoryMap['majorCategory'];
                            _filterParams['minorCategory'] =
                                categoryMap['minorCategory'];
                            _filterParams['color'] = result['color'] ?? 'null';
                          });
                          // 필터가 변경되었으므로 데이터를 다시 불러옴
                          _loadFoundItems();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 등록 버튼
          Positioned(
            top: 48,
            right: 16,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FoundItemForm()),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 위치 데이터 가져오기 함수
Future<Position> getLocationData() async {
  final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isLocationEnabled) {
    throw Exception('위치 서비스를 활성화해주세요.');
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw Exception('위치 권한을 허가해 주세요');
    }
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('앱의 위치 권한을 설정에서 허가해주세요.');
  }

  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}
