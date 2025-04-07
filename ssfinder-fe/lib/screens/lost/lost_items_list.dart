import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/lost_items_model.dart';
import 'package:sumsumfinder/widgets/lost/lost_item_card.dart';
import 'lost_item_detail.dart';
// 추천 항목 관련 import는 주석 처리
// import 'package:sumsumfinder/widgets/lost/recommended_card.dart';
// import 'recommended.dart';
// import 'package:sumsumfinder/models/found_item_model.dart';

class LostItemsList extends StatelessWidget {
  final List<LostItemListModel> items;

  const LostItemsList({Key? key, required this.items}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text('분실물 목록이 없습니다.'),
      );
    }
    
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final lostItem = items[index];

        // 추천 항목 관련 코드 주석 처리
        /*
        final List<dynamic> recommendationsData =
            lostItem.recommended['recommendations'] as List<dynamic>;

        final List<FoundItemModel> foundItems = recommendationsData
            .map((data) => FoundItemModel.fromJson(data))
            .toList();
        */

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 분실물 카드
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // item 전체가 아닌 itemId만 전달
                    builder: (_) => LostItemDetail(itemId: lostItem.id),
                  ),
                );
              },
              child: LostItemCard(item: lostItem),
            ),
            // 구분선 추가
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            
            // 추천 항목 관련 코드 주석 처리
            /*
            // 추천 항목이 있을 경우에만 추천 카드 표시
            if (foundItems.isNotEmpty)
              GestureDetector(
                onTap: () {
                  // 추천 카드 터치 시 Recommended 페이지로 이동하며 foundItems 전달
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          Recommended(recommendations: foundItems),
                    ),
                  );
                },
                child: RecommendedCard(
                  // foundItems 리스트에서 photo 값만 추출하여 최대 3개만 전달
                  imagePaths: foundItems
                      .map((item) => item.photo)
                      .take(3)
                      .toList(),
                ),
              ),
            */
          ],
        );
      },
    );
  }
}
