import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_item_model.dart';
import '../../widgets/found/found_item_card.dart';
import 'found_item_detail_police.dart';
import 'found_item_detail_sumsumfinder.dart';

class FoundItemsList extends StatefulWidget {
  final List<FoundItemListModel> foundItems;

  const FoundItemsList({Key? key, required this.foundItems}) : super(key: key);

  @override
  _FoundItemsListState createState() => _FoundItemsListState();
}

class _FoundItemsListState extends State<FoundItemsList> {
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();

  // 상수 정의
  static const _sheetInitialSize = 0.05;
  static const _sheetMaxSize = 0.8;
  static const _sheetMiddleSize = 0.5;
  static const _animationDuration = Duration(milliseconds: 200);
  static const _velocityThresholdFactor = 0.4;

  @override
  void dispose() {
    _draggableController.dispose();
    super.dispose();
  }

  Widget _buildHandle() => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onVerticalDragEnd: (details) {
      final screenHeight = MediaQuery.of(context).size.height;
      final threshold = screenHeight * _velocityThresholdFactor;

      if (details.velocity.pixelsPerSecond.dy < -threshold) {
        // 위로 빠르게 드래그 → 최대 크기
        _draggableController.animateTo(
          _sheetMaxSize,
          duration: _animationDuration,
          curve: Curves.easeOut,
        );
      } else if (details.velocity.pixelsPerSecond.dy > threshold) {
        // 아래로 빠르게 드래그 → 최소 크기
        _draggableController.animateTo(
          _sheetInitialSize,
          duration: _animationDuration,
          curve: Curves.easeOut,
        );
      } else {
        // 느린 드래그 → 중간 크기
        _draggableController.animateTo(
          _sheetMiddleSize,
          duration: _animationDuration,
          curve: Curves.easeOut,
        );
      }
    },
    child: Container(
      height: 38.3733,
      child: Center(
        child: Container(
          width: 50,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
      ),
    ),
  );

  Widget _buildContent(ScrollController scrollController) => Material(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
    color: const Color(0xFFF9FBFD),
    child: SafeArea(
      top: false,
      child: Column(
        children: [
          _buildHandle(),
          Expanded(
            child:
                widget.foundItems.isEmpty
                    ? const Center(child: Text('등록된 습득물이 없습니다'))
                    : ListView.builder(
                      controller: scrollController,
                      itemCount: widget.foundItems.length,
                      itemBuilder:
                          (context, index) =>
                              _buildListItem(widget.foundItems[index]),
                    ),
          ),
        ],
      ),
    ),
  );

  Widget _buildListItem(FoundItemListModel item) => GestureDetector(
    onTap: () => _navigateToDetail(item),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: FoundItemCard(item: item),
    ),
  );

  void _navigateToDetail(FoundItemListModel item) => Navigator.push(
    context,
    MaterialPageRoute(
      builder:
          (_) =>
              item.type == '경찰청'
                  ? FoundItemDetailPolice(id: item.id)
                  : FoundItemDetailSumsumfinder(id: item.id),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: _sheetInitialSize,
      minChildSize: _sheetInitialSize,
      maxChildSize: _sheetMaxSize,
      snap: true, // Snap 활성화
      snapSizes: const [_sheetInitialSize, _sheetMiddleSize, _sheetMaxSize],
      builder: (context, scrollController) => _buildContent(scrollController),
    );
  }
}
