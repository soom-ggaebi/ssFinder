import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/lost_items_model.dart';
import 'package:sumsumfinder/widgets/lost/lost_item_card.dart';
import 'lost_item_detail.dart';

// import 'package:sumsumfinder/widgets/lost/recommended_card.dart';
// import 'recommended.dart';
// import 'package:sumsumfinder/models/found_item_model.dart';

class LostItemsList extends StatefulWidget {
  final List<LostItemListModel> items;
  final Function(int, String) onItemStatusChanged;

  const LostItemsList({
    Key? key,
    required this.items,
    required this.onItemStatusChanged,
  }) : super(key: key);

  @override
  _LostItemsListState createState() => _LostItemsListState();
}

class _LostItemsListState extends State<LostItemsList> {
  late List<LostItemListModel> items;

  @override
  void initState() {
    super.initState();
    items = widget.items;
  }

  void _updateItemStatus(int id, String newStatus) {
    final index = items.indexWhere((item) => item.id == id);
    if (index != -1) {
      setState(() {
        items[index] = items[index].copyWith(status: newStatus);
      });
      widget.onItemStatusChanged(id, newStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(child: Text('분실물 목록이 없습니다.'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final lostItem = items[index];

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
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => LostItemDetail(
                          itemId: lostItem.id,
                          onStatusChanged: (id, status) {
                            final index = items.indexWhere(
                              (item) => item.id == id,
                            );
                            setState(() {
                              items[index] = items[index].copyWith(
                                status: status,
                              );
                            });
                          },
                        ),
                  ),
                );

                if (result != null && result is Map<String, dynamic>) {
                  if (result.containsKey('id') &&
                      result.containsKey('status')) {
                    _updateItemStatus(result['id'], result['status']);
                  }
                }
              },
              child: LostItemCard(item: lostItem),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),

            /*
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
