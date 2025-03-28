import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  late Box locationBox;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    await Hive.initFlutter();
    locationBox = await Hive.openBox('locationBox');
    await _initForegroundTask();
    _isInitialized = true;
  }

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'location_service_channel',
        channelName: 'Location Service',
        channelDescription:
            'This notification appears when the location service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// 백그라운드 위치 서비스 시작
  Future<void> startLocationService() async {
    // 메인에서 이미 위치 권한 요청을 완료했으므로,
    // 단순히 위치 서비스 활성 여부만 확인합니다.
    if (!await Geolocator.isLocationServiceEnabled()) {
      print("위치 서비스가 활성화되어 있지 않습니다.");
      return;
    }
    await FlutterForegroundTask.startService(
      notificationTitle: 'Location Service Running',
      notificationText: 'Tap to return to the app',
      callback: startCallback,
    );
  }

  Future<void> saveLocation(double latitude, double longitude) async {
    await locationBox.add({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> stopLocationService() async {
    await FlutterForegroundTask.stopService();
  }

  List<Map<dynamic, dynamic>> getAllLocations() {
    return locationBox.values.cast<Map<dynamic, dynamic>>().toList();
  }

  Future<void> clearAllLocations() async {
    await locationBox.clear();
  }

  /// 공통 위치 정보 가져오기 (앱 내 어디서든 재사용)
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('위치 서비스를 활성화해주세요.');
    }
    // 메인에서 권한 요청을 완료했으므로 단순 호출
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  Box? _locationBox;

  Future<void> _initializeServices() async {
    await Hive.initFlutter();
    _locationBox = await Hive.openBox('locationBox');
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('위치 정보 가져오기 오류: $e');
      return null;
    }
  }

  Future<void> _saveLocationToHive(double latitude, double longitude) async {
    if (_locationBox != null) {
      await _locationBox!.add({
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _initializeServices();
    final position = await _getCurrentLocation();
    if (position != null) {
      await _saveLocationToHive(position.latitude, position.longitude);
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _getCurrentLocation().then((position) async {
      if (position != null) {
        await _saveLocationToHive(position.latitude, position.longitude);
        print('위치 업데이트: ${position.latitude}, ${position.longitude}');
        FlutterForegroundTask.sendDataToMain({
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _locationBox?.close();
  }
}
