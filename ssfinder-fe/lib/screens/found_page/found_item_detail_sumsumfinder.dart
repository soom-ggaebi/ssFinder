import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_item_model.dart';

class FoundItemDetailSumsumfinder extends StatelessWidget {
  final FoundItemModel item;

  const FoundItemDetailSumsumfinder({Key? key, required this.item})
    : super(key: key);

  // 색상 이름에 따른 배경색 반환 함수
  Color getBackgroundColor(String colorName) {
    final List<Map<String, dynamic>> colorMapping = [
      {'label': '검정색', 'color': Colors.black},
      {'label': '회색', 'color': const Color(0xFFCCCCCC)},
      {'label': '베이지', 'color': const Color(0xFFE6C9A8)},
      {'label': '갈색', 'color': const Color(0xFFA67B5B)},
      {'label': '빨간색', 'color': const Color(0xFFCE464B)},
      {'label': '주황색', 'color': const Color(0xFFFFAD60)},
      {'label': '노란색', 'color': const Color(0xFFFFDD65)},
      {'label': '초록색', 'color': const Color(0xFF7FD17F)},
      {'label': '하늘색', 'color': const Color(0xFF80CCFF)},
      {'label': '파란색', 'color': const Color(0xFF5975FF)},
      {'label': '남색', 'color': const Color(0xFF2B298D)},
      {'label': '보라색', 'color': const Color(0xFFB771DF)},
      {'label': '분홍색', 'color': const Color(0xFFFF9FC0)},
    ];

    for (final mapping in colorMapping) {
      if (colorName == mapping['label']) {
        return mapping['color'] as Color;
      }
    }
    return Colors.blue[100]!;
  }

  String extractLocation(String location) {
    List<String> parts = location.split(" ");
    if (parts.length >= 4) {
      return parts.sublist(2, 4).join(" ");
    }
    return location;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '습득 상세 정보',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지와 소속
            Stack(
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: AssetImage(item.photo),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '숨숨파인더',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: getBackgroundColor(item.color),
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: Text(
                item.color,
                style: const TextStyle(fontSize: 14, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            // 카테고리
            Text(
              item.category,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            // 품목명
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            extractLocation(item.foundLocation),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            ' · ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            item.createdTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // 채팅하기 로직 구현
                  },
                  child: const Text('채팅하기', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 설명
            Text(item.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            // 습득 일자 및 습득 장소
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: const Text(
                '습득 일자',
                style: TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(item.foundDate, style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: const Text(
                '습득 장소',
                style: TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            // 습득 장소 지도 영역
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Text('습득 장소 지도 영역', style: TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
