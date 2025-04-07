import 'package:flutter/material.dart';
import 'package:sumsumfinder/widgets/common/custom_button.dart';
import '../../screens/found/found_item_form.dart';
import 'package:sumsumfinder/services/found_items_api_service.dart';

class MainOptionsPopup extends StatelessWidget {
  final dynamic item;
  final FoundItemsApiService _apiService = FoundItemsApiService();

  MainOptionsPopup({Key? key, this.item}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OptionItem(
            text: '수정하기',
            onTap: () {
             Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FoundItemForm(itemToEdit: item),
                ),
              );
            },
          ),
          OptionItem(
            text: '삭제하기',
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmDialog(context);
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
    }
    catch (e) {
      print('분실물 삭제에 실패했습니다: $e');
    }
  }
}
