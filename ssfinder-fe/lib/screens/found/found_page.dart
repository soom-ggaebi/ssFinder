import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../widgets/map_widget.dart';
import 'found_item_form.dart';
import 'found_item_filter.dart';
import 'found_items_list.dart';
import 'package:sumsumfinder/models/found_item_model.dart';
import 'package:sumsumfinder/services/api_service.dart';
import 'package:sumsumfinder/services/location_service.dart';

class FoundPage extends StatefulWidget {
  const FoundPage({Key? key}) : super(key: key);

  @override
  _FoundPageState createState() => _FoundPageState();
}

class _FoundPageState extends State<FoundPage> {
  Position? _currentPosition;
  String _searchQuery = "";
  List<FoundItemModel> foundItems = [];
  bool isLoading = true;

  // LocationService 인스턴스
  final LocationService _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
    _loadFoundItems(); // API 호출
  }

  Future<void> _loadCurrentLocation() async {
    try {
      // LocationService의 위치 정보
      Position pos = await _locationService.getCurrentPosition();
      setState(() {
        _currentPosition = pos;
      });
    } catch (e) {
      print('현재 위치 로드 실패: $e');
    }
  }

  Future<void> _searchAddress() async {
    if (_searchQuery.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(_searchQuery);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        // 새 좌표로 현재 위치 업데이트 (필요에 따라 지도 이동 처리)
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
      ).showSnackBar(const SnackBar(content: Text('주소 검색에 실패했습니다.')));
    }
  }

  Future<void> _loadFoundItems() async {
    try {
      List<FoundItemModel> items = await FoundItemsListApiService.getApiData();
      setState(() {
        foundItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('데이터 로딩에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도 영역
          _currentPosition != null
              ? MapWidget(
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
              )
              : const Center(child: CircularProgressIndicator()),
          // 습득물 목록
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : FoundItemsList(foundItems: foundItems),
          // 검색창 및 필터 버튼
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
                          MaterialPageRoute(
                            builder: (context) => const FilterPage(),
                          ),
                        );
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
