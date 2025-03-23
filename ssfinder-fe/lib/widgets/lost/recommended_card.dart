import 'package:flutter/material.dart';

class RecommendedCard extends StatelessWidget {
  /// 이미지 경로 리스트
  final List<String> imagePaths;

  const RecommendedCard({Key? key, required this.imagePaths}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 타이틀 문구와 캐릭터 아이콘
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "숨깨비가 물건을 찾아왔어요!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Image.asset(
                "assets/images/founditem.png",
                width: 24,
                height: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 가로로 스크롤되는 이미지 목록
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: imagePaths
                  .map((path) => _buildItemImage(path))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemImage(String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.asset(
          imagePath,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
