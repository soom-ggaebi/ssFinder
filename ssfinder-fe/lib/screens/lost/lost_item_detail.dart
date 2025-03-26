import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/lost_item_model.dart';

class LostItemDetail extends StatelessWidget {
  final LostItemModel item;

  const LostItemDetail({Key? key, required this.item}) : super(key: key);

  Color getBackgroundColor(String colorName) {
    const colorMapping = [
      {'label': '검정색', 'color': Colors.black},
      {'label': '회색', 'color': Color(0xFFCCCCCC)},
      {'label': '베이지', 'color': Color(0xFFE6C9A8)},
      {'label': '갈색', 'color': Color(0xFFA67B5B)},
      {'label': '빨간색', 'color': Color(0xFFCE464B)},
      {'label': '주황색', 'color': Color(0xFFFFAD60)},
      {'label': '노란색', 'color': Color(0xFFFFDD65)},
      {'label': '초록색', 'color': Color(0xFF7FD17F)},
      {'label': '하늘색', 'color': Color(0xFF80CCFF)},
      {'label': '파란색', 'color': Color(0xFF5975FF)},
      {'label': '남색', 'color': Color(0xFF2B298D)},
      {'label': '보라색', 'color': Color(0xFFB771DF)},
      {'label': '분홍색', 'color': Color(0xFFFF9FC0)},
    ];

    for (final mapping in colorMapping) {
      if (colorName == mapping['label']) {
        return mapping['color'] as Color;
      }
    }
    return Colors.blue[100]!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('분실 상세 정보'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
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
            const SizedBox(height: 16),
            // 색상 표시
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
            // 카테고리, 품목명 및 채팅방 버튼
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 및 품목명
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.category,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      Text(
                        item.itemName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 채팅방 버튼
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 40),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // 대화중인 채팅방으로 이동하는 로직
                  },
                  child: const Text(
                    '대화중인 채팅방',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // 분실 일자 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: const Text(
                '분실 일자',
                style: TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(
                item.lostDate,
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(height: 8),
            // 분실 장소 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(50.0),
              ),
              child: const Text(
                '분실 장소',
                style: TextStyle(fontSize: 14, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 8),
            // 지도 영역
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Text(
                  '분실 장소 지도 영역',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
