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

  LatLng _currentPosition = LatLng(35.160121, 126.851317);
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
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

      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_currentPosition));
      }

      await _loadNearbyStorages();
    } catch (e) {
      print('위치 정보를 가져오는데 실패했습니다: $e');
    }
  }

  Future<void> _loadNearbyStorages() async {
    List<String> queries = ["경찰청", "우체국"];
    const int radius = 5000;

    for (String query in queries) {
      String encodedQuery = Uri.encodeComponent(query);
      final url =
          'https://dapi.kakao.com/v2/local/search/keyword.json?query=$encodedQuery&x=${_currentPosition.longitude}&y=${_currentPosition.latitude}&radius=$radius';

      try {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'Authorization': 'KakaoAK ${EnvironmentConfig.kakaoApiKey}',
          },
        );
        final data = json.decode(response.body);

        if (data['meta'] != null && data['meta']['total_count'] > 0) {
          for (var document in data['documents']) {
            double lat = double.tryParse(document['y'].toString()) ?? 0;
            double lng = double.tryParse(document['x'].toString()) ?? 0;
            String placeName = document['place_name'] ?? query;
            String address = document['address_name'] ?? "";

            final markerColor = (query == "경찰청")
                ? BitmapDescriptor.hueAzure
                : BitmapDescriptor.hueRed;

            Marker marker = Marker(
              markerId: MarkerId(document['id'] != null
                  ? document['id']
                  : document['place_name'] + query),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(title: placeName, snippet: address),
              icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            );

            setState(() {
              _markers.add(marker);
            });
          }
        } else {
          print('$query 검색 결과가 없습니다.');
        }
      } catch (e) {
        print('Error loading nearby $query: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: 
        const Text(
            '내 주변 분실물 보관소',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
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
