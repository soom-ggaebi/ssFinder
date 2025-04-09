import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:sumsumfinder/config/environment_config.dart';

class NearbyStorageSelect extends StatefulWidget {
  const NearbyStorageSelect({Key? key}) : super(key: key);

  @override
  _NearbyStorageSelectState createState() => _NearbyStorageSelectState();
}

class _NearbyStorageSelectState extends State<NearbyStorageSelect> {
  GoogleMapController? _mapController;

  // 기본 위치 (임의의 초기값; 이후 실제 위치로 업데이트)
  LatLng _currentPosition = LatLng(35.160121, 126.851317);
  // 현재 위치 및 검색된 보관소 마커를 모두 저장할 집합
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // 현재 위치를 파악하고 지도 카메라 및 마커를 업데이트하는 함수
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // 서비스가 비활성화된 경우, 사용자에게 안내할 수 있습니다.
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        // 현재 위치 마커 (파란색)
        _markers.add(
          Marker(
            markerId: MarkerId('current'),
            position: _currentPosition,
            infoWindow: InfoWindow(title: '내 위치'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      });

      // 지도 컨트롤러가 준비되었다면 위치 이동 애니메이션 실행
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_currentPosition));
      }

      // 현재 위치를 기준으로 보관소 검색 실행
      await _loadNearbyStorages();
    } catch (e) {
      print('위치 정보를 가져오는데 실패했습니다: $e');
    }
  }

  // 카카오 로컬 검색 API를 사용하여 현재 위치 주변의 분실물 보관소 검색
  Future<void> _loadNearbyStorages() async {
    // 검색 키워드 (필요에 따라 수정)
    String query = "경찰";
    // 반경 (미터 단위; 여기서는 1000m 내)
    const radius = 5000;
    final url =
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeComponent(query)}&x=${_currentPosition.longitude}&y=${_currentPosition.latitude}&radius=$radius';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'KakaoAK ${EnvironmentConfig.kakaoApiKey}'},
      );

      final data = json.decode(response.body);

      print('# ${data}');

      if (data['meta'] != null && data['meta']['total_count'] > 0) {
        List markersList = [];
        for (var document in data['documents']) {
          // 카카오 API의 경우 위도(y)와 경도(x)는 문자열일 수 있으므로 변환합니다.
          double lat = double.tryParse(document['y'] as String) ?? 0;
          double lng = double.tryParse(document['x'] as String) ?? 0;
          String placeName = document['place_name'] ?? "보관소";
          String address = document['address_name'] ?? "";
          markersList.add(
            Marker(
              markerId: MarkerId(document['id'] ?? document['place_name']),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: placeName, snippet: address),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
            ),
          );
        }
        setState(() {
          _markers.addAll(markersList as Iterable<Marker>);
        });
      } else {
        print('검색 결과가 없습니다.');
      }
    } catch (e) {
      print('Error loading nearby storages: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 주변 분실물 보관소')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _currentPosition,
          zoom: 16,
        ),
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
        },
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
