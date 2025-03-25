import 'package:flutter/material.dart';
import '../../widgets/map_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import './found_item_form.dart';
import './found_item_filter.dart';
import 'found_items_list.dart'; // 수정된 FoundItemsList 위젯 import
import 'package:sumsumfinder/models/found_item_model.dart';
import 'package:sumsumfinder/services/api_service.dart';

class FoundPage extends StatefulWidget {
  FoundPage({Key? key}) : super(key: key);

  @override
  _FoundPageState createState() => _FoundPageState();
}

class _FoundPageState extends State<FoundPage> {
  Position? _currentPosition;
  String _searchQuery = "";

  // 추가: API에서 가져온 데이터와 로딩 상태 변수
  List<FoundItemModel> foundItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _getLocationData();
    _loadFoundItems(); // 페이지가 생성될 때 API 호출
  }

  Future<void> _getLocationData() async {
    try {
      Position pos = await getLocationData();
      setState(() {
        _currentPosition = pos;
      });
    } catch (e) {
      // 위치 데이터 에러 처리
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
    try {
      List<FoundItemModel> items = await FoundItemsListApiService.getApiData();
      setState(() {
        foundItems = items;
        isLoading = false;
      });
    } catch (e) {
      // API 호출 실패 시 에러 처리
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 로딩에 실패했습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 지도 영역: 현재 위치가 있으면 해당 좌표로, 없으면 FutureBuilder로 가져옴.
          _currentPosition != null
              ? MapWidget(
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
              )
              : FutureBuilder<Position>(
                future: getLocationData(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData &&
                      snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData) {
                    Position pos = snapshot.data!;
                    return MapWidget(
                      latitude: pos.latitude,
                      longitude: pos.longitude,
                    );
                  } else {
                    return MapWidget();
                  }
                },
              ),
          // 하단 드래그 시트 영역: API 데이터 로딩 여부에 따라 처리
          isLoading
              ? Center(child: CircularProgressIndicator())
              : FoundItemsList(foundItems: foundItems),
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
