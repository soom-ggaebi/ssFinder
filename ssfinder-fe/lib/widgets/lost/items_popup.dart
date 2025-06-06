import 'package:flutter/material.dart';
import 'package:sumsumfinder/widgets/common/custom_button.dart';
import '../../screens/lost/lost_item_form.dart';
import 'package:sumsumfinder/services/lost_items_api_service.dart';
import 'package:sumsumfinder/models/lost_items_model.dart';

class MainOptionsPopup extends StatelessWidget {
  final LostItemModel item;
  final Function(LostItemModel) onUpdate;
  final LostItemsApiService _apiService = LostItemsApiService();

  MainOptionsPopup({Key? key, required this.item, required this.onUpdate})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool currentNotificationEnabled = item.notificationEnabled;
    final bool isCurrentlyLost = item.status == "LOST";
    final String toggleStatusOptionText =
        isCurrentlyLost ? "찾은물건으로 변경" : "숨은물건으로 변경";

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OptionItem(
            text: '수정하기',
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LostItemForm(itemToEdit: item),
                ),
              );
              if (result == true) {
                try {
                  final updatedResponse = await _apiService.getLostItemDetail(
                    lostId: item.id,
                  );
                  final updatedItem = LostItemModel.fromJson(updatedResponse);
                  onUpdate(updatedItem);
                } catch (e) {
                  print('수정 후 분실물 정보를 불러오는데 실패했습니다: $e');
                }
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
            text: currentNotificationEnabled ? '알림끄기' : '알림켜기',
            onTap: () async {
              Navigator.pop(context);
              _updateNotificationSettings(!currentNotificationEnabled);
            },
          ),
          OptionItem(
            text: toggleStatusOptionText,
            onTap: () async {
              Navigator.pop(context);
              final String newStatus = isCurrentlyLost ? "FOUND" : "LOST";
              try {
                await _apiService.updateLostItemStatus(
                  lostId: item.id,
                  status: newStatus,
                );
                final updatedItem = item.copyWith(status: newStatus);
                onUpdate(updatedItem);
                print('상태가 변경되었습니다.');
              } catch (e) {
                print('상태가 변경에 실패하였습니다: ${e}');
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
                _deleteLostItem(context);
              },
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteLostItem(BuildContext context) async {
    try {
      await _apiService.deleteLostItem(lostId: item.id);
      print('분실물 삭제에 성공했습니다');
    } catch (e) {
      print('분실물 삭제에 실패했습니다: $e');
    }
  }

  Future<void> _updateNotificationSettings(bool enabled) async {
    try {
      final result = await _apiService.updateNotificationSettings(
        lostId: item.id,
        notificationEnabled: enabled,
      );
      final updatedItem = item.copyWith(notificationEnabled: enabled);
      onUpdate(updatedItem);
      print('알림 설정 업데이트 결과: $result');
    } catch (e) {
      print('Error updating notification settings: $e');
    }
  }
}
