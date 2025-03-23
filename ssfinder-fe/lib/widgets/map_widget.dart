import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  // 기본 위치
  static final LatLng companyLatLng = LatLng(35.160121, 126.851317);

  // 전달받은 위치
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
    // 전달받은 위치가 없으면 기본 위치 사용
    LatLng targetLocation =
        (latitude != null && longitude != null)
            ? LatLng(latitude!, longitude!)
            : companyLatLng;

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: targetLocation, zoom: 16),
    );
  }
}
