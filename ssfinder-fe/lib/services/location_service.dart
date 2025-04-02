import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as developer;
import './notification_service.dart';

/// 위치 데이터 저장에 필요한 상수들
class LocationConstants {
  static const int maxLocations = 1000;
  static const double minDistanceFilter = 15.0;
  static const String boxName = 'locationBox';
  static const String channelId = 'location_service_channel';
  static const String channelName = 'Location Service';
  static const String notificationTitle = '위치 서비스 실행 중';
  static const String notificationText = '앱으로 돌아가려면 탭하세요';
  static const int minTimeBetweenUpdates = 3; // 최소 3초 간격 업데이트
}

/// 위치 정보를 저장하는 데이터 클래스
class LocationData {
  final double latitude;
  final double longitude;
  final String timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
    };
  }

  factory LocationData.fromMap(Map<dynamic, dynamic> map) {
    return LocationData(
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      timestamp: map['timestamp'] as String,
    );
  }

  @override
  String toString() =>
      'LocationData(lat: $latitude, lng: $longitude, time: $timestamp)';
}

/// 위치 서비스를 관리하는 클래스
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  late Box<Map<dynamic, dynamic>> locationBox;
  bool _isInitialized = false;
  final _initLock = Completer<void>();

  // 백그라운드 서비스 상태 변수
  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;

  Future<void> initialize() async {
    if (_isInitialized) return _initLock.future;

    await Hive.initFlutter();
    locationBox = await Hive.openBox<Map<dynamic, dynamic>>(
      LocationConstants.boxName,
    );
    await _initForegroundTask();
    _isInitialized = true;
    _initLock.complete();

    return _initLock.future;
  }

  Future<void> _initForegroundTask() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: LocationConstants.channelId,
        channelName: LocationConstants.channelName,
        channelDescription: '위치 서비스 실행 시 표시되는 알림입니다.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(3000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<bool> startLocationService() async {
    await initialize();
    await FlutterForegroundTask.startService(
      notificationTitle: LocationConstants.notificationTitle,
      notificationText: LocationConstants.notificationText,
      callback: startCallback,
    );
    _isServiceRunning = true;
    return true;
  }

  Future<void> saveLocation(double latitude, double longitude) async {
    if (!_isInitialized) await initialize();

    if (locationBox.length >= LocationConstants.maxLocations) {
      await locationBox.deleteAt(0);
    }

    await locationBox.add({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<bool> stopLocationService() async {
    await FlutterForegroundTask.stopService();
    await serverSendLocations();
    _isServiceRunning = false;
    return true;
  }

  List<LocationData> getAllLocations() {
    if (!_isInitialized) {
      developer.log('LocationService가 초기화되지 않았습니다.', name: 'LocationService');
      return [];
    }

    return locationBox.values.map((map) => LocationData.fromMap(map)).toList();
  }

  Future<void> clearAllLocations() async {
    if (!_isInitialized) await initialize();
    await locationBox.clear();
  }

  Future<Position> getCurrentPosition() async {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  Future<void> serverSendLocations() async {
    if (!_isInitialized) await initialize();

    List<LocationData> locations = getAllLocations();
    developer.log(
      "저장된 위치 정보 (총 ${locations.length}개):",
      name: 'LocationService',
    );

    for (var location in locations) {
      developer.log(
        "위도: ${location.latitude}, 경도: ${location.longitude}, 시간: ${location.timestamp}",
        name: 'LocationService',
      );
    }

    await clearAllLocations();
    developer.log("저장된 모든 위치 정보가 삭제되었습니다.", name: 'LocationService');
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  Box<Map<dynamic, dynamic>>? _locationBox;
  Position? _lastPosition;
  DateTime? _lastSavedTime;

  Future<void> _initializeServices() async {
    await Hive.initFlutter();
    _locationBox = await Hive.openBox<Map<dynamic, dynamic>>(
      LocationConstants.boxName,
    );
    developer.log('위치 서비스 초기화 완료', name: 'LocationTaskHandler');
  }

  Future<Position?> _getCurrentLocation() async {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  Future<void> _saveLocationToHive(double latitude, double longitude) async {
    if (_locationBox == null) {
      developer.log('Hive 박스가 초기화되지 않았습니다.', name: 'LocationTaskHandler');
      return;
    }

    if (_locationBox!.length >= LocationConstants.maxLocations) {
      await _locationBox!.deleteAt(0);
    }

    final now = DateTime.now();
    final locationData = {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': now.toIso8601String(),
    };

    await _locationBox!.add(locationData);

    // 이동을 시작할 때, 마지막 저장 이후 10분 이상 경과 시 날씨 알림을 전송합니다.
    if (_lastSavedTime != null) {
      final minutesSinceLastSave = now.difference(_lastSavedTime!).inMinutes;
      if (minutesSinceLastSave >= 10) {
        await NotificationService().showWeatherNotification();
      }
    }

    _lastSavedTime = now;

    developer.log('위치 저장됨: $latitude, $longitude', name: 'LocationTaskHandler');
  }

  bool _shouldSaveLocation(Position position) {
    if (_lastPosition == null) return true;

    final now = DateTime.now();
    if (_lastSavedTime != null) {
      final secondsSinceLastSave = now.difference(_lastSavedTime!).inSeconds;
      if (secondsSinceLastSave < LocationConstants.minTimeBetweenUpdates) {
        return false;
      }
    }

    final distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      position.latitude,
      position.longitude,
    );

    return distance >= LocationConstants.minDistanceFilter;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await dotenv.load(fileName: ".env");

    await _initializeServices();

    final position = await _getCurrentLocation();
    if (position != null) {
      _lastPosition = position;
      await _saveLocationToHive(position.latitude, position.longitude);
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _getCurrentLocation().then((position) async {
      if (position != null) {
        // 위치 업데이트 처리 여부 확인
        final shouldSave = _shouldSaveLocation(position);

        // 현재 위치와 변화 거리 계산
        double? distance;
        if (_lastPosition != null) {
          distance = Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );

          developer.log(
            '현재 위치: ${position.latitude}, ${position.longitude} (변화 거리: ${distance.toStringAsFixed(2)} 미터)',
            name: 'LocationTaskHandler',
          );
        }

        if (shouldSave) {
          await _saveLocationToHive(position.latitude, position.longitude);
          _lastPosition = position;

          // 앱 메인 화면에 위치 정보 전송
          FlutterForegroundTask.sendDataToMain({
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': DateTime.now().toIso8601String(),
            'distance': distance,
          });
        }
      }
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _locationBox?.close();
    developer.log('위치 서비스 종료됨', name: 'LocationTaskHandler');
  }
}
