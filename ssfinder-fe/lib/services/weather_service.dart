import 'package:http/http.dart' as http;
import 'package:sumsumfinder/config/environment_config.dart';
import 'dart:convert';

class WeatherService {
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    final response = await http.get(
      Uri.parse(
        '${EnvironmentConfig.weatherBaseUrl}?lat=$lat&lon=$lon&appid=${EnvironmentConfig.weatherApiKey}&units=metric',
      ),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      throw Exception('Weather data not found');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized access');
    } else {
      throw Exception('Failed to load weather data: ${response.reasonPhrase}');
    }
  }
}
