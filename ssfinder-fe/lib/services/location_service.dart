import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  late Box locationBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    locationBox = await Hive.openBox('locationBox');
  }

  Future<void> saveLocation(double latitude, double longitude) async {
    await locationBox.add({
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}
