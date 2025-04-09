import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:sumsumfinder/config/environment_config.dart';

import 'found_map.dart';
import 'found_items_list.dart';
import 'found_item_filter.dart';
import 'found_item_form.dart';
import 'package:sumsumfinder/models/found_items_model.dart';
import 'package:sumsumfinder/services/found_items_api_service.dart';

class FoundPage extends StatefulWidget {
  final String? initialSearchQuery;

  FoundPage({Key? key, this.initialSearchQuery}) : super(key: key);

  @override
  _FoundPageState createState() => _FoundPageState();
}

class _FoundPageState extends State<FoundPage> {
  Position? _currentPosition;
  String _searchQuery = "";
  List<FoundItemCoordinatesModel> foundItems = [];
  bool isLoading = true;
  GoogleMapController? _mapController;
  Map<String, dynamic> _filterParams = {
    'status': 'All',
    'type': '전체',
    'foundAt': '',
    'majorCategory': '',
    'minorCategory': '',
    'color': '',
  };
  List<int>? _selectedClusterItemIds;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!;
      _searchPlaceByKakao(_searchQuery);
    }
    else {
    _getLocationData();
    }
  }

  Future<void> _getLocationData() async {
    try {
      Position pos = await getLocationData();
      setState(() {
        _currentPosition = pos;
      });
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
        );
      }
      _loadFoundItems();
    } catch (e) {
      setState(() {
        _currentPosition = Position(
          latitude: 35.160121,
          longitude: 126.851317,
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

  Future<void> _searchPlaceByKakao(String keyword) async {
    if (keyword.isEmpty) return;

    final String url =
        'https://dapi.kakao.com/v2/local/search/keyword.json?query=${Uri.encodeComponent(keyword)}';
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'KakaoAK ${EnvironmentConfig.kakaoApiKey}'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['documents'] != null && data['documents'].isNotEmpty) {
          final firstItem = data['documents'][0];
          double longitude = double.parse(firstItem['x']);
          double latitude = double.parse(firstItem['y']);

          setState(() {
            _currentPosition = Position(
              latitude: latitude,
              longitude: longitude,
              timestamp: DateTime.now(),
              accuracy: 0,
              altitude: 0,
              heading: 0,
              speed: 0,
              speedAccuracy: 0,
              altitudeAccuracy: 0,
              headingAccuracy: 0,
            );
            _selectedClusterItemIds = null;
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(latitude, longitude)),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('검색 결과가 없습니다.')));
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('카카오맵 API 호출에 실패했습니다.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  Map<String, String> _splitCategory(String? category) {
    if (category == null || category.trim().isEmpty)
      return {'majorCategory': '', 'minorCategory': ''};
    final parts = category.split(' > ');
    return parts.length >= 2
        ? {'majorCategory': parts[0].trim(), 'minorCategory': parts[1].trim()}
        : {'majorCategory': category.trim(), 'minorCategory': ''};
  }

  Future<void> _loadFoundItems() async {
    if (_mapController == null || !mounted) return;
    try {
      final bounds = await _mapController!.getVisibleRegion();
      final items = await FoundItemsApiService().getFilteredFoundItems(
        maxLat: bounds.northeast.latitude,
        maxLng: bounds.northeast.longitude,
        minLat: bounds.southwest.latitude,
        minLng: bounds.southwest.longitude,
        status: _filterParams['status'],
        type: _filterParams['type'],
        foundAt: _filterParams['foundAt'],
        majorCategory: _filterParams['majorCategory'],
        minorCategory: _filterParams['minorCategory'],
        color: _filterParams['color'],
      );
      setState(() {
        foundItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 로딩에 실패하였습니다')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FoundMap(
            latitude: _currentPosition?.latitude ?? 35.160121,
            longitude: _currentPosition?.longitude ?? 126.851317,
            onMapCreated: (controller) {
              _mapController = controller;
              _loadFoundItems();
            },
            onCameraIdle: _loadFoundItems,
            foundItems: foundItems,
            onClusterTap: (List<int> itemIds) {
              setState(() {
                _selectedClusterItemIds = itemIds;
              });
            },
            onMapTap: () {
              setState(() {
                _selectedClusterItemIds = null;
              });
            },
          ),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : FoundItemsList(
                itemIds:
                    _selectedClusterItemIds ??
                    foundItems.map((item) => item.id).toList(),
              ),
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
                      onPressed: () => _searchPlaceByKakao(_searchQuery),
                    ),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: '장소 검색',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) => _searchPlaceByKakao(value),
                        onChanged: (value) {
                          _searchQuery = value;
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.tune),
                      onPressed: () async {
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
                            _filterParams['status'] = result['state'] ?? 'All';
                            _filterParams['type'] = result['type'] ?? '전체';
                            _filterParams['foundAt'] = result['foundAt'] ?? '';
                            final categoryMap = _splitCategory(
                              result['category'],
                            );
                            _filterParams['majorCategory'] =
                                categoryMap['majorCategory'];
                            _filterParams['minorCategory'] =
                                categoryMap['minorCategory'];
                            _filterParams['color'] = result['color'] ?? '';
                            _selectedClusterItemIds = null;
                          });
                          _loadFoundItems();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
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

Future<Position> getLocationData() async {
  final isEnabled = await Geolocator.isLocationServiceEnabled();
  if (!isEnabled) throw Exception('위치 서비스를 활성화해 주세요');
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied)
      throw Exception('위치 권한을 허가해 주세요');
  }
  if (permission == LocationPermission.deniedForever)
    throw Exception('앱의 위치 권한을 설정에서 허가해 주세요');
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}
