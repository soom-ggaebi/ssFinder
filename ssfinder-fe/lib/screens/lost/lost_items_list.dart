import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/lost_items_model.dart';
import 'package:sumsumfinder/widgets/lost/lost_item_card.dart';
import 'lost_item_detail.dart';
import 'package:sumsumfinder/widgets/lost/recommended_card.dart';
import 'recommended.dart';

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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LostItemDetail(
                      itemId: lostItem.id,
                      onStatusChanged: (id, status) {
                        final index = items.indexWhere((item) => item.id == id);
                        setState(() {
                          items[index] = items[index].copyWith(status: status);
                        });
                      },
                    ),
                  ),
                );

                if (result != null &&
                    result is Map<String, dynamic> &&
                    result.containsKey('id') &&
                    result.containsKey('status')) {
                  _updateItemStatus(result['id'], result['status']);
                }
              },
              child: LostItemCard(item: lostItem),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            if (lostItem.matched_image_urls != null &&
                (lostItem.matched_image_urls as List).isNotEmpty)
              GestureDetector(
                onTap: () {
                  // 추천 페이지로 넘어갈 때 lostItemId 값을 전달합니다.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Recommended(lostItemId: lostItem.id),
                    ),
                  );
                },
                child: RecommendedCard(
                  image: (lostItem.matched_image_urls as List<dynamic>)
                      .map((url) => url.toString())
                      .take(3)
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }
}
