import 'package:flutter/material.dart';
import '../../widgets/map_widget.dart';
import 'package:geolocator/geolocator.dart';

class FoundPage extends StatelessWidget {
  FoundPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('주웠어요')),
      body: FutureBuilder<Position>(
        future: getLocationData(),
        builder: (context, snapshot) {
          // 로딩 상태
          if (!snapshot.hasData &&
              snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          // 권한 허가된 상태
          if (snapshot.hasData) {
            Position pos = snapshot.data!;
            return MapWidget(latitude: pos.latitude, longitude: pos.longitude);
          }
          // 권한 없는 상태
          else {
            return MapWidget();
          }
        },
      ),
    );
  }
}

Future<Position> getLocationData() async {
  // 위치 서비스 활성화 여부 확인
  final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
  // 위치 서비스 활성화 안 됨
  if (!isLocationEnabled) {
    throw Exception('위치 서비스를 활성화해주세요.');
  }

  // 위치 권한 확인
  LocationPermission permission = await Geolocator.checkPermission();
  // 위치 권한 거절됨
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    // 위치 권한 요청하기
    if (permission == LocationPermission.denied) {
      throw Exception('위치 권한을 허가해 주세요');
    }
  }

  // 위치 권한 거절됨 (앱에서 재요청 불가)
  if (permission == LocationPermission.deniedForever) {
    throw Exception('앱의 위치 권한을 설정에서 허가해주세요.');
  }

  // 위 모든 조건이 통과되면 현재 위치 데이터 전송
  return await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
}
