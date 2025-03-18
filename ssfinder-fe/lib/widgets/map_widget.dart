import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  static final LatLng companyLatLng = LatLng(37.5244273, 126.921252);

  const MapWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: companyLatLng, zoom: 16),
    );
  }
}
