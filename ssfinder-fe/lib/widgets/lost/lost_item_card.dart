import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/lost_item_model.dart';

class LostItemCard extends StatelessWidget {
  final LostItemModel item;

  const LostItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final bool isFound = item.status; // true: 찾은 물건, false: 숨은 물건
    final Color labelBackground = isFound ? Colors.lightGreen[100]! : Colors.pink[100]!;
    final Color labelBorder = isFound ? Colors.green : Colors.red;
    final Color labelTextColor = isFound ? Colors.green : Colors.red;
    final String labelText = isFound ? '찾은물건' : '숨은물건';
    final bool isNotificationOn = item.isNotificationOn;

    final contentRow = Row(
      children: [
        // 사진
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            item.photo,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 20),
        // 카테고리, 이름, 알림 상태
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리
              Text(
                item.category,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              // 분실물 이름
              Text(
                item.itemName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // 알림 상태 표시
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.yellow[100], // 연한 노란색 배경
                  border: Border.all(color: Colors.yellow[700]!), // 짙은 노랑 테두리
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isNotificationOn ? '알림 받는 중' : '알림 꺼짐',
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2F9), // 배경색 #EBF2F9
        border: const Border(
          bottom: BorderSide(color: Colors.grey), // 하단에만 회색 테두리
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: contentRow,
    );

    // 찾은 물건인 경우 흑백 처리
    if (isFound) {
      cardContent = ColorFiltered(
        colorFilter: const ColorFilter.matrix(
          <double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0,      0,      0,      1, 0,
          ],
        ),
        child: cardContent,
      );
    }

    return Stack(
      children: [
        cardContent,
        // 찾은 물건이면 검정 반투명 오버레이 적용
        if (isFound)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        // 오른쪽 상단 상태
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: labelBackground,
              border: Border.all(color: labelBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              labelText,
              style: TextStyle(fontSize: 12, color: labelTextColor),
            ),
          ),
        ),
      ],
    );
  }
}
