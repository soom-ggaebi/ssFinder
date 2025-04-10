import 'package:flutter/material.dart';
import 'lost_items_list.dart';
import 'lost_item_form.dart';
import 'package:sumsumfinder/models/lost_items_model.dart';
import 'package:sumsumfinder/services/lost_items_api_service.dart'; // 수정: 올바른 API 서비스 import
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LostPage extends StatefulWidget {
  const LostPage({Key? key}) : super(key: key);

  @override
  _LostPageState createState() => _LostPageState();
}

class _LostPageState extends State<LostPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LostItemsApiService _apiService = LostItemsApiService();

  // 탭 목록: 전체, 숨은물건, 찾은물건
  final List<String> _tabs = ['전체', '숨은물건', '찾은물건'];

  // API로부터 받아온 분실물 데이터와 로딩 상태 변수
  List<LostItemListModel> _lostItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // 탭 컨트롤러 초기화
    _tabController = TabController(length: _tabs.length, vsync: this);
    // API 호출하여 분실물 데이터 로드
    _loadLostItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// API를 호출하여 분실물 데이터를 가져오는 함수
  Future<void> _loadLostItems() async {
    try {
      final response = await _apiService.getLostItems();

      final List<dynamic> itemsJson = response['data'] as List<dynamic>;
      print('#### ${itemsJson}');

      final items =
          itemsJson
              .map(
                (item) =>
                    LostItemListModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();

      setState(() {
        _lostItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그인이 필요합니다.')));
      print('erre: ${e}');
    }
  }

  /// 탭별 데이터 필터링 함수
  List<LostItemListModel> _getFilteredItems(String tab) {
    if (tab == '전체') {
      return _lostItems;
    } else if (tab == '숨은물건') {
      // 숨은물건: status가 "LOST"인 경우
      return _lostItems.where((item) => item.status == "LOST").toList();
    } else if (tab == '찾은물건') {
      // 찾은물건: status가 "FOUND"인 경우
      return _lostItems.where((item) => item.status == "FOUND").toList();
    }
    return [];
  }

  void _handleItemStatusChanged(int itemId, String newStatus) {
    setState(() {
      // 해당 ID의 아이템 찾아서 상태 업데이트
      for (int i = 0; i < _lostItems.length; i++) {
        if (_lostItems[i].id == itemId) {
          // 새 상태로 아이템 업데이트
          _lostItems[i] = LostItemListModel(
            id: _lostItems[i].id,
            userId: _lostItems[i].userId,
            color: _lostItems[i].color,
            majorCategory: _lostItems[i].majorCategory,
            minorCategory: _lostItems[i].minorCategory,
            title: _lostItems[i].title,
            lostAt: _lostItems[i].lostAt,
            image: _lostItems[i].image,
            status: newStatus,
            matched_image_urls: _lostItems[i].matched_image_urls,
          );
          break;
        }
      }
    });
  }

  /// 각 탭에 해당하는 목록을 보여주는 위젯
  Widget _buildTabContent(String tab) {
    List<LostItemListModel> filteredItems = _getFilteredItems(tab);
    return LostItemsList(
      items: filteredItems,
      onItemStatusChanged: _handleItemStatusChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '나의 분실물', isFromBottomNav: false),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  // 탭과 탭뷰로 분실물 목록을 표시
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue,
                          tabs: _tabs.map((e) => Tab(text: e)).toList(),
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children:
                              _tabs
                                  .map((tab) => _buildTabContent(tab))
                                  .toList(),
                        ),
                      ),
                    ],
                  ),
                  // 분실물 등록 버튼
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Material(
                      elevation: 2,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LostItemForm(),
                            ),
                          );
                        },
                        customBorder: const CircleBorder(),
                        child: Container(
                          height: 50,
                          width: 50,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
