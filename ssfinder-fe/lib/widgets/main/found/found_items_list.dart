import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_items_model.dart'; // FoundItemListModel이 정의되어 있습니다.
import 'package:sumsumfinder/widgets/main/found/found_item_card.dart';      // 개별 습득물 카드를 표시하는 위젯
import '../../../screens/found/found_item_detail_sumsumfinder.dart';         // 습득물 상세 페이지 (예시)

class FoundItemsList extends StatefulWidget {
  final List<FoundItemListModel> items;
  final Function(int, String) onItemStatusChanged;

  const FoundItemsList({
    Key? key,
    required this.items,
    required this.onItemStatusChanged,
  }) : super(key: key);

  @override
  _FoundItemsListState createState() => _FoundItemsListState();
}

class _FoundItemsListState extends State<FoundItemsList> {
  late List<FoundItemListModel> items;

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
      return const Center(child: Text('습득물 목록이 없습니다.'));
    }

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final foundItem = items[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoundItemDetailSumsumfinder(
                      id: foundItem.id,
                      // onStatusChanged: (id, status) {
                      //   final index = items.indexWhere((item) => item.id == id);
                      //   setState(() {
                      //     items[index] = items[index].copyWith(status: status);
                      //   });
                      // },
                    ),
                  ),
                );

                if (result != null && result is Map<String, dynamic>) {
                  if (result.containsKey('id') && result.containsKey('status')) {
                    _updateItemStatus(result['id'], result['status']);
                  }
                }
              },
              child: FoundItemCard(item: foundItem),
            ),
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          ],
        );
      },
    );
  }
}
