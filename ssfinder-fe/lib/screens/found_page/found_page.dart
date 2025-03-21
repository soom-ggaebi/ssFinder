import 'package:flutter/material.dart';
import '../../widgets/map_widget.dart';
import './found_items_list.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class FoundPage extends StatefulWidget {
  FoundPage({Key? key}) : super(key: key);

  @override
  _FoundPageState createState() => _FoundPageState();
}

class _FoundPageState extends State<FoundPage> {
  Position? _currentPosition;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _getLocationData();
  }

  Future<void> _getLocationData() async {
    try {
      Position pos = await getLocationData();
      setState(() {
        _currentPosition = pos;
      });
    } catch (e) {
      // 에러 처리
    }
  }

  /// 주소 검색: 입력한 주소 -> 좌표
  Future<void> _searchAddress() async {
    if (_searchQuery.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(_searchQuery);
      if (locations.isNotEmpty) {
        Location location = locations.first;
        // 새 좌표를 기반으로 현재 위치를 업데이트
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          FoundItemsList(),

          // 상단 검색 창 (돋보기 아이콘이 왼쪽)
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(32),
              child: Container(
                height: 50,
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: _searchAddress,
                    ),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: '위치 검색',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          _searchQuery = value;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 기존 위치 데이터 가져오기 함수 (변경 없음)
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
