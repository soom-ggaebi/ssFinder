import 'package:flutter/material.dart';
import 'package:sumsumfinder/widgets/common/custom_button.dart';
import '../../screens/found/found_item_form.dart';
import 'package:sumsumfinder/services/found_items_api_service.dart';

class MainOptionsPopup extends StatelessWidget {
  final dynamic item;
  final FoundItemsApiService _apiService = FoundItemsApiService();
  final VoidCallback? onUpdated;

  MainOptionsPopup({Key? key, this.item, this.onUpdated}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isCurrentlyStored = item.status == "STORED";
    String toggleOptionText = isCurrentlyStored ? "돌려준물건으로 변경" : "보관중인물건으로 변경";

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OptionItem(
            text: '수정하기',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoundItemForm(itemToEdit: item),
                ),
              );
              if (result == true && onUpdated != null) {
                onUpdated!();
              }
            },
          ),
          OptionItem(
            text: '삭제하기',
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmDialog(context);
            },
          ),
          OptionItem(
            text: toggleOptionText,
            onTap: () async {
              final newStatus = isCurrentlyStored ? "RECEIVED" : "STORED";
              try {
                await _apiService.updateFoundItemStatus(
                  foundId: item.id,
                  status: newStatus,
                );
                if (onUpdated != null) {
                  onUpdated!();
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('상태가 변경되었습니다.')));
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('상태 변경에 실패했습니다: $e')));
              }
            },
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: const BoxDecoration(color: Color(0xFFF8F8F8)),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Text(
                '창닫기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('분실물 삭제'),
          content: const Text('정말 이 분실물을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteLostItem();
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLostItem() async {
    try {
      await _apiService.deleteFoundItem(foundId: item.id);
      print('분실물 삭제에 성공했습니다');
    } catch (e) {
      print('분실물 삭제에 실패했습니다: $e');
    }
  }
}
