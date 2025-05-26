import 'package:flutter/material.dart';
import 'package:sumsumfinder/services/weather_service.dart';
import 'package:sumsumfinder/widgets/main/location_search_bar.dart';
import 'package:sumsumfinder/services/location_service.dart';

import 'package:geolocator/geolocator.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Future<Map<String, dynamic>> _getCurrentWeather() async {
    Position position = await LocationService().getCurrentPosition();

    return await WeatherService.getWeather(
      position.latitude,
      position.longitude,
    );
  }

  Map<String, String> _getWeatherAssets(Map<String, dynamic> weatherData) {
    final weatherList = weatherData['weather'] as List<dynamic>;
    final weatherMain =
        weatherList.isNotEmpty ? weatherList[0]['main'] as String : '';

    String backgroundImage;
    String weatherMessage;
    String weatherTip;
    String weatherEmoji;

    switch (weatherMain) {
      case "Rain":
        backgroundImage = 'assets/images/main/weather_rain.png';
        weatherMessage = '비가 와요!';
        weatherTip = '우산 꼭 챙기세요!';
        weatherEmoji = '🌧️';
        break;
      case "Clear":
        backgroundImage = 'assets/images/main/weather_clear.png';
        weatherMessage = '맑은 날씨입니다!';
        weatherTip = '화창한 날엔 선글라스로 눈부심을 막으세요!';
        weatherEmoji = '🌞';
        break;
      case "Clouds":
        backgroundImage = 'assets/images/main/weather_cloudy.png';
        weatherMessage = '구름이 많아요!';
        weatherTip = '흐린 날에도 필요할 때 우산 준비하세요!';
        weatherEmoji = '☁️';
        break;
      case "Snow":
        backgroundImage = 'assets/images/main/weather_snow.png';
        weatherMessage = '눈이 와요!';
        weatherTip = '우산 꼭 챙기세요!';
        weatherEmoji = '☃️';
        break;
      default:
        backgroundImage = 'assets/images/main/weather_default.png';
        weatherMessage = '오늘의 날씨를 확인해보세요!';
        weatherTip = '날씨에 맞게 준비해보세요!';
        weatherEmoji = '🍬';
        break;
    }
    return {
      'image': backgroundImage,
      'message': weatherMessage,
      'tip': weatherTip,
      'emoji': weatherEmoji,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getCurrentWeather(),
      builder: (context, snapshot) {
        // 기본 배경 및 멘트
        String backgroundImage = 'assets/images/main/weather_default.png';
        String weatherMessage = '오늘의 날씨를 확인해보세요!';
        String weatherTip = '날씨에 맞게 준비해보세요!';
        String weatherEmoji = '🍬';
        if (snapshot.hasData) {
          final assets = _getWeatherAssets(snapshot.data!);
          backgroundImage = assets['image']!;
          weatherMessage = assets['message']!;
          weatherTip = assets['tip']!;
          weatherEmoji = assets['emoji']!;
        }
        return Container(
          width: double.infinity,
          height: 210,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0)),
          child: Stack(
            children: [
              // 배경 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.asset(
                  backgroundImage,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              // 오버레이 (어둡게 처리)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
              // 이모티콘 추가 (오른쪽 상단)
              Positioned(
                top: 12.0,
                right: 12.0,
                child: Text(
                  weatherEmoji,
                  style: TextStyle(fontSize: 28.0), // 크기 조정
                ),
              ),
              // 내용 컨테이너: 날씨 텍스트와 검색창 포함
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    // Column 안의 위젯들을 세로 방향으로 아래쪽에 배치합니다.
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 날씨 정보 텍스트
                      Row(
                        children: [
                          const Text(
                            '오늘의 날씨는? ',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            weatherMessage,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5.0),
                      Text(
                        weatherTip,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12.0),
                      // 검색창
                      const LocationSearchBar(),
                    ],
                  ),
                ),
              ),
              // 데이터 로딩 중일 때 표시되는 로딩 인디케이터
              if (snapshot.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      },
    );
  }
}
