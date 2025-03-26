import 'package:flutter/material.dart';

class WeatherWidget extends StatelessWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0)),
      child: Stack(
        children: [
          // 배경 이미지
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.asset(
              'assets/images/main/weather_rain.png',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          // 오버레이
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ),
          // 내용 컨테이너
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('오늘의 날씨는? ', style: TextStyle(color: Colors.white)),
                      Text('💧비💧', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 5.0),
                  const Text(
                    '우산 챙기는 거 잊지 마세요!',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 9.0,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFD1D1D1).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.white, size: 18),
                        SizedBox(width: 6.0),
                        Text(
                          '내 주변 분실물을 검색해보세요!',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
