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

  // 추가: API에서 가져온 데이터와 로딩 상태 변수
  List<FoundItemCoordinatesModel> foundItems = [];
  bool isLoading = true;

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getLocationData();
  }

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
            latitude: 35.160121, // FoundMap.companyLatLng의 위도
            longitude: 126.851317, // FoundMap.companyLatLng의 경도
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

  /// 주소 검색: 입력한 주소 -> 좌표
  Future<void> _searchAddress() async {
    if (_searchQuery.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(_searchQuery);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        // 새 좌표를 기반으로 현재 위치 업데이트
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

  /// API를 호출하여 습득물 데이터를 가져오는 함수
  Future<void> _loadFoundItems() async {
    if (_mapController == null || !mounted) return;

    try {
      final bounds = await _mapController!.getVisibleRegion();
      final items = await FoundItemsApiService().getFoundItemCoordinates(
        maxLat: bounds.northeast.latitude,
        maxLng: bounds.northeast.longitude,
        minLat: bounds.southwest.latitude,
        minLng: bounds.southwest.longitude,
      );
      
      if (mounted) { // 위젯이 여전히 트리에 있는지 확인
        setState(() {
          foundItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) { // 위젯이 여전히 트리에 있는지 확인
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터 로딩에 실패했습니다.'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FoundMap(
            latitude: _currentPosition?.latitude ?? 35.160121, // 기본 위치(광주)
            longitude: _currentPosition?.longitude ?? 126.851317, // 기본 위치(광주)
            onMapCreated: (controller) {
              _mapController = controller;
              _loadFoundItems();
            },
            onCameraIdle: _loadFoundItems,
            foundItems: foundItems,
            onClusterTap: (List<int> itemIds) {
            },
          ),
          // 하단 드래그 시트 영역: API 데이터 로딩 여부에 따라 처리
          isLoading
              ? Center(child: CircularProgressIndicator())
              : FoundItemsList(itemIds: foundItems.map((item) => item.id).toList()),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => FilterPage()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 추가: 등록 버튼
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

/// 위치 데이터 가져오기
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
