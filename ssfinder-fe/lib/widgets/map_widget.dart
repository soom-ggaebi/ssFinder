import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  static final LatLng companyLatLng = LatLng(35.160121, 126.851317);
  final double? latitude;
  final double? longitude;
  final ValueChanged<String>? onLocationSelected;

  const MapWidget({
    Key? key,
    this.latitude,
    this.longitude,
    this.onLocationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final LatLng targetLocation =
        (latitude != null && longitude != null)
            ? LatLng(latitude!, longitude!)
            : companyLatLng;

    // 마커 설정
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('item_location'),
        position: targetLocation, // 핀 위치
        infoWindow: const InfoWindow(title: '보관 장소'), // 터치 시 표시될 텍스트
      ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: targetLocation, zoom: 16),
      markers: markers, // 마커 추가
    );
  }
}
