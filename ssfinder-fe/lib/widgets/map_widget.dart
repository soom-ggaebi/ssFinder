// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';

// class MapWidget extends StatefulWidget {
//   /// 전체 화면으로 사용할지 여부 (true면 부모 위젯이 전체 공간을 차지하도록 해야 함)
//   final bool fullScreen;

//   /// 지도 생성 완료 후 호출되는 콜백 (선택 사항)
//   final void Function(GoogleMapController)? onMapCreated;

//   /// 초기 카메라 위치 (옵션)
//   final CameraPosition initialPosition;

//   const MapWidget({
//     Key? key,
//     this.fullScreen = false,
//     this.onMapCreated,
//     this.initialPosition = const CameraPosition(
//       target: LatLng(37.5665, 126.9780), // 기본은 서울
//       zoom: 12,
//     ),
//   }) : super(key: key);

//   @override
//   _MapWidgetState createState() => _MapWidgetState();
// }

// class _MapWidgetState extends State<MapWidget> {
//   GoogleMapController? _controller;

//   @override
//   Widget build(BuildContext context) {
//     // fullScreen이 true면 부모 위젯이 Expanded나 SizedBox.expand 등을 사용하여
//     // 전체 공간을 제공해야 함.
//     return Container(
//       width: widget.fullScreen ? double.infinity : 300,
//       height: widget.fullScreen ? double.infinity : 300,
//       child: GoogleMap(
//         initialCameraPosition: widget.initialPosition,
//         onMapCreated: (controller) {
//           _controller = controller;
//           if (widget.onMapCreated != null) {
//             widget.onMapCreated!(controller);
//           }
//         },
//         // 필요한 경우 마커, 지도 스타일 등 추가 설정 가능
//       ),
//     );
//   }
// }
