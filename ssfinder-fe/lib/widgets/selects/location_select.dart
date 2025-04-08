import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sumsumfinder/config/environment_config.dart';

class LocationSelect extends StatefulWidget {
  @override
  _LocationSelectState createState() => _LocationSelectState();
}

class _LocationSelectState extends State<LocationSelect> {
  GoogleMapController? _mapController;

  // 초기값: 기본 위치 또는 현재 위치
  LatLng _cameraPosition = LatLng(35.160121, 126.851317);

  // 사용자가 선택한 좌표
  LatLng? _selectedLatLng;

  // 역지오코딩 결과 주소
  String? _selectedAddress_name;
  String? _selectedAddress_street;

  // 주소 검색 쿼리
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// 위치 권한 확인 및 현재 위치 가져오기
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _cameraPosition = LatLng(position.latitude, position.longitude);
    });
  }

  /// 역지오코딩: 좌표 -> 주소 (Google Maps Geocoding API 사용)
  Future<void> _reverseGeocode(LatLng latLng) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${latLng.latitude},${latLng.longitude}&key=${EnvironmentConfig.googleMapApiKey}&language=ko'; // 한국어로 결과 받기

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final results = data['results'];
        if (results.isNotEmpty) {
          // 첫 번째 결과의 formatted_address 사용
          final formattedAddress = results[0]['formatted_address'];
          // 건물명 또는 POI 이름 (있는 경우)
          String placeName = '';

          // 주소 구성요소에서 건물명 또는 POI 찾기
          for (var component in results[0]['address_components']) {
            if (component['types'].contains('point_of_interest') ||
                component['types'].contains('establishment')) {
              placeName = component['long_name'];
              break;
            }
          }

          setState(() {
            _selectedAddress_name = placeName.isNotEmpty ? placeName : '선택한 위치';
            _selectedAddress_street = formattedAddress;
          });
        }
      } else {
        throw Exception('Geocoding API error: ${data['status']}');
      }
    } catch (e) {
      print('Error in reverse geocoding: $e');
      setState(() {
        _selectedAddress_street = '주소를 가져올 수 없습니다.';
      });
    }
  }

  /// 주소 검색: 입력한 주소 -> 좌표 (Google Maps Geocoding API 사용)
  Future<void> _searchAddress() async {
    if (_searchQuery.isEmpty) return;

    final apiKey = 'YOUR_GOOGLE_API_KEY'; // Google API 키 입력
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(_searchQuery)}&key=$apiKey&language=ko';

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (data['status'] == 'OK') {
        final results = data['results'];
        if (results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          LatLng searchedLatLng = LatLng(location['lat'], location['lng']);

          // 지도 카메라 이동
          _mapController?.animateCamera(CameraUpdate.newLatLng(searchedLatLng));

          // 선택된 좌표 업데이트 및 역지오코딩
          setState(() {
            _selectedLatLng = searchedLatLng;
          });
          _reverseGeocode(searchedLatLng);
        }
      } else {
        throw Exception('Geocoding API error: ${data['status']}');
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
      appBar: AppBar(
        title: Text(
          '습득장소 선택',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 구글 맵 영역
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _cameraPosition,
                zoom: 16,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              // 지도 탭 시 선택된 좌표 업데이트 및 역지오코딩
              onTap: (LatLng latLng) {
                setState(() {
                  _selectedLatLng = latLng;
                });
                _reverseGeocode(latLng);
              },
              // 카메라 이동 시 중앙 좌표 업데이트
              onCameraMove: (position) {
                _cameraPosition = position.target;
              },
              markers:
                  _selectedLatLng != null
                      ? {
                        Marker(
                          markerId: MarkerId('selected'),
                          position: _selectedLatLng!,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure,
                          ),
                        ),
                      }
                      : {},
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            // 상단 검색 창
            Positioned(
              top: 16,
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
                          onChanged: (value) => _searchQuery = value,
                          onSubmitted: (_) => _searchAddress(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 하단 주소 + 버튼 영역
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 건물명
                    Text(
                      _selectedAddress_name ?? '물건을 주우신 위치를 알려주세요!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // 도로명
                    Text(
                      _selectedAddress_street ?? '게시글에는 상세 위치 정보를 공개하지 않습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 16),
                    // "현재 위치로 설정" 버튼
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size.fromHeight(48),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed:
                          _selectedLatLng == null
                              ? null
                              : () {
                                // 위치 정보와 함께 주소 반환
                                Navigator.pop(context, {
                                  'location': _selectedAddress_street,
                                  'latitude': _selectedLatLng!.latitude,
                                  'longitude': _selectedLatLng!.longitude,
                                });
                              },
                      child: Text('현재 위치로 설정'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
