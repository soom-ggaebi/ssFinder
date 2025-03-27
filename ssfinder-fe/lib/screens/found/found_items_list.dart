import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_item_model.dart';
import '../../widgets/found/found_item_card.dart';
import 'found_item_detail_police.dart';
import 'found_item_detail_sumsumfinder.dart'; // 상세정보 페이지 import

class FoundItemsList extends StatelessWidget {
  final List<FoundItemModel> foundItems; // 외부에서 전달받은 데이터

  const FoundItemsList({Key? key, required this.foundItems}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      // 초기 높이, 최소 높이, 최대 높이
      initialChildSize: 0.04,
      minChildSize: 0.04,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFF9FBFD),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10.0),
            ],
          ),
          // 목록
          child: ListView.builder(
            controller: scrollController,
            itemCount: foundItems.length,
            itemBuilder: (context, index) {
              final item = foundItems[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) =>
                              item.source == '경찰청'
                                  ? FoundItemDetailPolice(item: item)
                                  : FoundItemDetailSumsumfinder(item: item),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: FoundItemCard(item: item),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
