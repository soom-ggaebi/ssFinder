import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:developer' as developer;

import './notification_service.dart';
import './location_api_service.dart';

/// 위치 데이터 저장에 필요한 상수들
class LocationConstants {
  static const int maxLocations = 1000;
  static const double minDistanceFilter = 0.3;
  static const String boxName = 'locationBox';
  static const String channelId = 'location_service_channel';
  static const String channelName = 'Location Service';
  static const String notificationTitle = '위치 서비스 실행 중';
  static const String notificationText = '앱으로 돌아가려면 탭하세요';
  static const int minTimeBetweenUpdates = 5; // 최소 5초
  static const int weatherNotificationInterval = 30; // 30분
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

/// Hive에 데이터를 추가하고, 최대 개수를 초과하면 서버 전송 후 초기화
Future<void> _addToHiveAndSendIfNeeded(
  Box<Map<dynamic, dynamic>> box,
  double latitude,
  double longitude,
) async {
  if (box.length >= LocationConstants.maxLocations) {
    final route =
        box.values.map((map) => Map<String, dynamic>.from(map)).toList();

    try {
      await LocationApiService().sendLocationData(route);
      await box.clear(); // 성공 시 초기화
    } catch (e) {
      developer.log('서버 전송 실패: $e', name: 'LocationService');
      // 실패 시에는 그대로 둠
    }
  }

  // 새 위치 데이터 추가
  await box.add({
    'latitude': latitude,
    'longitude': longitude,
    'timestamp': DateTime.now().toIso8601String(),
  });
}

/// 위치 서비스를 관리하는 클래스 (메인 이소레이트)
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  late Box<Map<dynamic, dynamic>> locationBox;
  bool _isInitialized = false;
  final _initLock = Completer<void>();

  // 백그라운드 서비스 상태
  bool _isServiceRunning = false;
  bool get isServiceRunning => _isServiceRunning;

  // 거리/시간 필터를 위한 상태
  Position? _lastPosition;
  DateTime? _lastSavedTime;

  Future<void> initialize() async {
    if (_isInitialized) return _initLock.future;

    _isInitialized = true;

    // 1) Hive 초기화
    await Hive.initFlutter();
    locationBox = await Hive.openBox<Map<dynamic, dynamic>>(
      LocationConstants.boxName,
    );

    // 2) Foreground Task 초기화
    await _initForegroundTask();

    // 3) 백그라운드 데이터 수신 세팅
    FlutterForegroundTask.addTaskDataCallback((data) {
      if (data is Map) {
        _handleBackgroundData(data);
      }
    });

    _initLock.complete();
    return _initLock.future;
  }

  /// 백그라운드 이소레이트에서 넘어온 위치 정보 처리
  void _handleBackgroundData(Map data) async {
    final latitude = data['latitude'] as double?;
    final longitude = data['longitude'] as double?;
    final currentTime = DateTime.now();

    if (latitude == null || longitude == null) {
      developer.log('백그라운드에서 잘못된 위치 데이터가 왔습니다.', name: 'LocationService');
      return;
    }

    // 거리/시간 필터 체크
    if (_shouldSaveLocation(latitude, longitude, currentTime)) {
      // 조건을 만족하면 DB에 저장
      await _addToHiveAndSendIfNeeded(locationBox, latitude, longitude);
      developer.log('위치 저장 완료: $latitude, $longitude', name: 'LocationService');

      // 날씨 알림 처리
      _handleWeatherNotificationLogic();

      // 마지막 위치/시간 갱신(Position 객체를 생성할 때 반드시 제공해야 하는 필드)
      _lastPosition = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: currentTime,
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
      _lastSavedTime = currentTime;
    } else {
      developer.log('거리/시간 조건 불충족으로 위치 저장 안 함', name: 'LocationService');
    }
  }

  /// 시간 간격/이동 거리에 따라 저장 필요 여부 판단
  bool _shouldSaveLocation(double lat, double lon, DateTime currentTime) {
    if (_lastSavedTime != null) {
      final secondsSinceLast =
          currentTime.difference(_lastSavedTime!).inSeconds;
      if (secondsSinceLast < LocationConstants.minTimeBetweenUpdates) {
        return false;
      }
    }

    // 거리 필터
    if (_lastPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastPosition!.latitude,
        _lastPosition!.longitude,
        lat,
        lon,
      );
      if (distance < LocationConstants.minDistanceFilter) {
        return false;
      }
    }

    return true;
  }

  /// 날씨 알림
  Future<void> _handleWeatherNotificationLogic() async {
    if (_lastSavedTime != null) {
      final minutesSinceLastSave =
          DateTime.now().difference(_lastSavedTime!).inMinutes;
      if (minutesSinceLastSave >=
          LocationConstants.weatherNotificationInterval) {
        await NotificationService().showWeatherNotification();
      }
    }
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
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// 위치 서비스 시작 (백그라운드 이소레이트 시작)
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

  /// 위치 서비스 중지
  Future<bool> stopLocationService() async {
    await FlutterForegroundTask.stopService();
    await serverSendLocations(); // 중지 직후 서버 전송
    _isServiceRunning = false;
    return true;
  }

  /// 위치 저장
  Future<void> saveLocation(double latitude, double longitude) async {
    if (!_isInitialized) await initialize();
    await _addToHiveAndSendIfNeeded(locationBox, latitude, longitude);
  }

  /// 전체 위치 데이터 조회
  List<LocationData> getAllLocations() {
    if (!_isInitialized) {
      developer.log('LocationService가 초기화되지 않았습니다.', name: 'LocationService');
      return [];
    }
    return locationBox.values.map((map) => LocationData.fromMap(map)).toList();
  }

  /// 전체 위치 데이터 삭제
  Future<void> clearAllLocations() async {
    if (!_isInitialized) await initialize();
    await locationBox.clear();
  }

  /// 현재 위치 가져오기
  Future<Position> getCurrentPosition() async {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
    );
    return await Geolocator.getCurrentPosition(
      locationSettings: locationSettings,
    );
  }

  /// 서버 전송 후 로컬 DB 비우기
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

    final route = locations.map((loc) => loc.toMap()).toList();
    await LocationApiService().sendLocationData(route);

    await clearAllLocations();
    developer.log("저장된 모든 위치 정보가 삭제되었습니다.", name: 'LocationService');
  }
}

/// 백그라운드 이소레이트 시작점
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

/// 위치 정보를 백그라운드에서 수집해 메인 이소레이트로 전송만 담당
class LocationTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await dotenv.load(fileName: ".env");
    developer.log('백그라운드 위치 서비스 onStart', name: 'LocationTaskHandler');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // 주기적으로 위치를 가져와 메인 이소레이트로 보냄
    _getCurrentLocation().then((position) {
      if (position != null) {
        final dataToSend = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().toIso8601String(),
        };
        FlutterForegroundTask.sendDataToMain(dataToSend);

        developer.log(
          '백그라운드 → 메인 이소레이트 위치 전송: '
          '${position.latitude}, ${position.longitude}',
          name: 'LocationTaskHandler',
        );
      }
    });
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      final LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
    } catch (e) {
      developer.log('위치 정보를 가져오는 중 오류: $e', name: 'LocationTaskHandler');
      return null;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    developer.log('백그라운드 위치 서비스 onDestroy', name: 'LocationTaskHandler');
  }
}
