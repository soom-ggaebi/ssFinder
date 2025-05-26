import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_items_model.dart';
import 'package:sumsumfinder/services/found_items_api_service.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import '../../widgets/found/found_item_card.dart';
import 'found_item_detail_police.dart';
import 'found_item_detail_sumsumfinder.dart';

class FoundItemsList extends StatefulWidget {
  final List<int> itemIds;

  const FoundItemsList({Key? key, required this.itemIds}) : super(key: key);

  @override
  _FoundItemsListState createState() => _FoundItemsListState();
}

class _FoundItemsListState extends State<FoundItemsList> {
  final DraggableScrollableController _draggableController =
      DraggableScrollableController();
  final FoundItemsApiService _apiService = FoundItemsApiService();
  final KakaoLoginService _kakaoLoginService = KakaoLoginService();

  List<FoundItemListModel> foundItems = [];
  bool isLoading = true;
  bool isLoadingMore = false;

  // 페이지네이션 관련 변수
  int currentPage = 0;
  int totalPages = 1;
  bool isLastPage = false;

  // 스크롤 컨트롤러
  ScrollController? _scrollController;

  // 상수 정의
  static const _sheetInitialSize = 0.06;
  static const _sheetMaxSize = 0.8;
  static const _sheetMiddleSize = 0.5;
  static const _animationDuration = Duration(milliseconds: 200);
  static const _velocityThresholdFactor = 0.4;

  @override
  void initState() {
    super.initState();
    _loadClusterItems();
  }

  @override
  void didUpdateWidget(FoundItemsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemIds != widget.itemIds) {
      currentPage = 0;
      foundItems.clear();
      _loadClusterItems();
    }
  }

  Future<void> _loadClusterItems() async {
    if (isLoadingMore) return;

    setState(() {
      isLoading = foundItems.isEmpty;
      isLoadingMore = !isLoading && !isLastPage;
    });

    try {
      final result = await _apiService.getClusterDetailItems(
        ids: widget.itemIds,
        page: currentPage,
        size: 10,
        sortBy: 'createdAt',
        sortDirection: 'desc',
      );

      final List<FoundItemListModel> items = result['items'];
      final int pages = result['totalPages'];
      final bool lastPage = result['isLastPage'];

      setState(() {
        if (currentPage == 0) {
          foundItems = items;
        } else {
          foundItems.addAll(items);
        }
        totalPages = pages;
        isLastPage = lastPage;
        isLoading = false;
        isLoadingMore = false;
      });
    } catch (e) {
      print('Error loading cluster items: $e');
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
    }
  }

  void _loadNextPage() {
    if (!isLastPage && !isLoadingMore) {
      currentPage++;
      _loadClusterItems();
    }
  }

  void _setupScrollController(ScrollController controller) {
    _scrollController = controller;
    _scrollController!.addListener(() {
      if (_scrollController!.position.pixels >=
              _scrollController!.position.maxScrollExtent - 200 &&
          !isLoading &&
          !isLoadingMore &&
          !isLastPage) {
        _loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _draggableController.dispose();
    _scrollController?.dispose();
    super.dispose();
  }

  Widget _buildHandle() => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onVerticalDragEnd: (details) {
      final screenHeight = MediaQuery.of(context).size.height;
      final threshold = screenHeight * _velocityThresholdFactor;
      if (_draggableController.isAttached) {
        if (details.velocity.pixelsPerSecond.dy < -threshold) {
          _draggableController.animateTo(
            _sheetMaxSize,
            duration: _animationDuration,
            curve: Curves.easeOut,
          );
        } else if (details.velocity.pixelsPerSecond.dy > threshold) {
          _draggableController.animateTo(
            _sheetInitialSize,
            duration: _animationDuration,
            curve: Curves.easeOut,
          );
        } else {
          _draggableController.animateTo(
            _sheetMiddleSize,
            duration: _animationDuration,
            curve: Curves.easeOut,
          );
        }
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

  // 반환값을 받아 상태 업데이트 처리
  void _navigateToDetail(FoundItemListModel item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) =>
                item.type == '경찰청'
                    ? FoundItemDetailPolice(id: item.id)
                    : FoundItemDetailSumsumfinder(id: item.id),
      ),
    );

    if (result != null &&
        result is Map<String, dynamic> &&
        result.containsKey('id') &&
        result.containsKey('status')) {
      _updateItemStatus(result['id'], result['status']);
    }
  }

  // 리스트 내 해당 아이템 상태 변경
  void _updateItemStatus(int id, String newStatus) {
    final index = foundItems.indexWhere((item) => item.id == id);
    if (index != -1) {
      setState(() {
        foundItems[index] = foundItems[index].copyWith(status: newStatus);
      });
    }
  }

  Widget _buildListItem(FoundItemListModel item) => GestureDetector(
    onTap: () => _navigateToDetail(item),
    child: Padding(
      padding: const EdgeInsets.only(bottom: 16.0, left: 16.0, right: 16.0),
      child: ValueListenableBuilder<bool>(
        valueListenable: _kakaoLoginService.isLoggedIn,
        builder: (context, isLoggedIn, child) {
          return FoundItemCard(item: item, isLoggedIn: isLoggedIn);
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _draggableController,
      initialChildSize: _sheetMiddleSize,
      minChildSize: _sheetInitialSize,
      maxChildSize: _sheetMaxSize,
      snap: true,
      snapSizes: const [_sheetInitialSize, _sheetMiddleSize, _sheetMaxSize],
      builder: (context, scrollController) {
        _setupScrollController(scrollController);
        return Material(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          color: const Color(0xFFF9FBFD),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                _buildHandle(),
                Expanded(
                  child:
                      isLoading
                          ? _buildPlaceholderList()
                          : foundItems.isEmpty
                          ? const Center(child: Text('등록된 습득물이 없습니다'))
                          : ListView.builder(
                            controller: scrollController,
                            itemCount:
                                foundItems.length + (isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == foundItems.length) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              return _buildListItem(foundItems[index]);
                            },
                          ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _buildPlaceholderList() {
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    },
  );
}
