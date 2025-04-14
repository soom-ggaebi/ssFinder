import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sumsumfinder/config/environment_config.dart';

import '../../services/location_api_service.dart';

class LocationSelect extends StatefulWidget {
  final String? date;

  const LocationSelect({Key? key, this.date}) : super(key: key);

  @override
  _LocationSelectState createState() => _LocationSelectState();
}

class _LocationSelectState extends State<LocationSelect> {
  GoogleMapController? _mapController;

  // 기본 위치
  LatLng _cameraPosition = LatLng(35.160121, 126.851317);

  LatLng? _selectedLatLng;

  String? _selectedAddress_name;
  String? _selectedAddress_street;

  String _searchQuery = "";

  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();

    if (widget.date != null) {
      _loadRouteData().then((_) {
        if (_selectedLatLng != null) {
          _reverseGeocode(_selectedLatLng!);
        } else {
          _determinePosition();
        }
      });
    } else {
      _determinePosition().then((_) {
        if (_selectedLatLng != null) {
          _reverseGeocode(_selectedLatLng!);
        }
      });
    }
  }

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
      _selectedLatLng = LatLng(position.latitude, position.longitude);
    });

    await _reverseGeocode(_selectedLatLng!);

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    }
  }

  Future<void> _loadRouteData() async {
    final locationApiService = LocationApiService();
    try {
      final response = await locationApiService.getLocationRoutes(widget.date!);
      if (response['success'] == true) {
        final routes = response['data']['routes'] as List<dynamic>;
        List<LatLng> routeCoordinates = [];
        for (var route in routes) {
          final lat = route['latitude'] as double;
          final lng = route['longitude'] as double;
          routeCoordinates.add(LatLng(lat, lng));
        }
        if (routeCoordinates.isNotEmpty) {
          setState(() {
            _polylines.add(
              Polyline(
                polylineId: PolylineId('route'),
                points: routeCoordinates,
                width: 4,
                color: Colors.deepOrangeAccent,
              ),
            );
            _selectedLatLng = routeCoordinates[0];
            _cameraPosition = routeCoordinates[0];
          });

          await _reverseGeocode(_selectedLatLng!);

          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(routeCoordinates[0]),
            );
          }
        }
      } else {
        print('API 호출은 성공했으나, 응답 결과가 성공 상태가 아닙니다.');
      }
    } catch (e) {
      print('Error loading route data: $e');
    }
  }

  Future<void> _reverseGeocode(LatLng latLng) async {
    final url =
        'https://dapi.kakao.com/v2/local/geo/coord2address.json?x=${latLng.longitude}&y=${latLng.latitude}';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'KakaoAK ${EnvironmentConfig.kakaoApiKey}'},
      );
      final data = json.decode(response.body);

      if (data['meta'] != null && data['meta']['total_count'] > 0) {
        String address = "";
        String addressName = "";

        if (data['documents'][0]['road_address'] != null) {
          address = data['documents'][0]['road_address']['address_name'];
        } else if (data['documents'][0]['address'] != null) {
          address = data['documents'][0]['address']['address_name'];
        }

        addressName =
            (data['documents'][0]['road_address']?['building_name']
                        ?.toString()
                        .isNotEmpty ==
                    true)
                ? data['documents'][0]['road_address']['building_name']
                : '선택한 장소';
        setState(() {
          _selectedAddress_street = address;
          _selectedAddress_name = addressName;
        });
      } else {
        setState(() {
          _selectedAddress_street = "주소를 찾을 수 없습니다.";
        });
      }
    } catch (e) {
      print('Kakao reverse geocoding error: $e');
      setState(() {
        _selectedAddress_street = '주소를 가져올 수 없습니다.';
      });
    }
  }

  // 주소 검색 기능
  Future<void> _searchAddress() async {
    if (_searchQuery.isEmpty) return;
    final url =
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeComponent(_searchQuery)}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'KakaoAK ${EnvironmentConfig.kakaoApiKey}'},
      );
      final data = json.decode(response.body);
      if (data['meta'] != null && data['meta']['total_count'] > 0) {
        final firstResult = data['documents'][0];
        double latitude = double.parse(firstResult['y']);
        double longitude = double.parse(firstResult['x']);
        LatLng searchedLatLng = LatLng(latitude, longitude);

        _mapController?.animateCamera(CameraUpdate.newLatLng(searchedLatLng));
        setState(() {
          _selectedLatLng = searchedLatLng;
        });
        _reverseGeocode(searchedLatLng);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('검색 결과가 없습니다.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('주소 검색에 실패하였습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '습득장소 선택',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _cameraPosition,
                zoom: 16,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
              },
              onTap: (LatLng latLng) {
                setState(() {
                  _selectedLatLng = latLng;
                });
                _reverseGeocode(latLng);
              },
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
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
            // 주소 검색창
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
                            hintText: '주소 검색',
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
            // 하단에 선택된 위치 정보 및 버튼 표시
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
                    Text(
                      _selectedAddress_name ?? '물건을 주우신 위치를 알려주세요!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _selectedAddress_street ?? '게시글에는 상세 위치 정보를 공개하지 않습니다.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 16),
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
