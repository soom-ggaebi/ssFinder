import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sumsumfinder/models/found_items_model.dart';
import 'dart:ui' as ui;

class FoundMap extends StatefulWidget {
  static const LatLng companyLatLng = LatLng(35.160121, 126.851317);
  
  final double? latitude;
  final double? longitude;
  final List<FoundItemCoordinatesModel> foundItems;
  final Function(GoogleMapController)? onMapCreated;
  final Function()? onCameraIdle;
  final Function(List<int> itemIds)? onClusterTap;

  const FoundMap({
    Key? key,
    this.latitude,
    this.longitude,
    this.foundItems = const [],
    this.onMapCreated,
    this.onCameraIdle,
    this.onClusterTap,
  }) : super(key: key);

  @override
  _FoundPageMapState createState() => _FoundPageMapState();
}

class _FoundPageMapState extends State<FoundMap> {
  final Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _createClusters();
  }

  @override
  void didUpdateWidget(FoundMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.foundItems != widget.foundItems) {
      _createClusters();
    }
  }

  void _createClusters() async {
    if (widget.foundItems.isEmpty) {
      setState(() {
        _markers.clear();
      });
      return;
    }

    // 클러스터링 로직: 근접한 아이템들을 그룹화
    Map<String, List<FoundItemCoordinatesModel>> clusters = {};

    for (var item in widget.foundItems) {
      String key = '${item.latitude.toStringAsFixed(3)},${item.longitude.toStringAsFixed(3)}';
      clusters.putIfAbsent(key, () => []).add(item);
    }

    final newMarkers = <Marker>{};
    
    for (var entry in clusters.entries) {
      final items = entry.value;
      final position = LatLng(
        double.parse(entry.key.split(',')[0]), 
        double.parse(entry.key.split(',')[1]),
      );

      final marker = await _buildClusterMarker(position, items);
      newMarkers.add(marker);
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(newMarkers);
    });
  }

  Future<Marker> _buildClusterMarker(
      LatLng position, List<FoundItemCoordinatesModel> items) async {
    final isCluster = items.length > 0;

    return Marker(
      markerId: MarkerId(isCluster ? 'cluster_${position.hashCode}' : 'item_${items.first.id}'),
      position: position,
      icon: await _getMarkerBitmap(
        isCluster ? 125 : 75,
        text: isCluster ? items.length.toString() : null,
      ),
      onTap: () => widget.onClusterTap?.call(items.map((e) => e.id).toList()),
    );
  }

  Future<BitmapDescriptor> _getMarkerBitmap(int size, {String? text}) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = Colors.blue;
    
    canvas.drawCircle(Offset(size / 2, size / 2), size / 2, paint);
    
    if (text != null) {
      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: size / 3,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      painter.layout();
      painter.paint(
        canvas,
        Offset(size / 2 - painter.width / 2, size / 2 - painter.height / 2),
      );
    }
    
    final img = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    LatLng targetLocation =
        (widget.latitude != null && widget.longitude != null)
            ? LatLng(widget.latitude!, widget.longitude!)
            : FoundMap.companyLatLng;

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: targetLocation, zoom: 16),
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      markers: _markers,
      onMapCreated: (controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
      },
      onCameraIdle: widget.onCameraIdle,
    );
  }
}
