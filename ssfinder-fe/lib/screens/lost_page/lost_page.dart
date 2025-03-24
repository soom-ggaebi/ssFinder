import 'package:flutter/material.dart';
import 'lost_items_list.dart';
import 'lost_item_form.dart';
import 'package:sumsumfinder/models/lost_item_model.dart';
import 'package:sumsumfinder/service/api_service.dart';

/// LostPage는 분실물 데이터를 API로 받아와 탭별로 필터링하여 보여주는 페이지입니다.
class LostPage extends StatefulWidget {
  const LostPage({Key? key}) : super(key: key);

  @override
  _LostPageState createState() => _LostPageState();
}

class _LostPageState extends State<LostPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // 탭 목록: 전체, 숨은물건, 찾은물건
  final List<String> _tabs = ['전체', '숨은물건', '찾은물건'];

  // API로부터 받아온 분실물 데이터와 로딩 상태 변수
  List<LostItemModel> _lostItems = [];
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
      List<LostItemModel> items = await LostItemsListApiService.getApiData();
      setState(() {
        _lostItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('데이터 로딩에 실패했습니다.')),
      );
    }
  }

  /// 탭별 데이터 필터링 함수
  List<LostItemModel> _getFilteredItems(String tab) {
    if (tab == '전체') {
      return _lostItems;
    } else if (tab == '숨은물건') {
      // 숨은물건: status가 false인 경우
      return _lostItems.where((item) => item.status == false).toList();
    } else if (tab == '찾은물건') {
      // 찾은물건: status가 true인 경우
      return _lostItems.where((item) => item.status == true).toList();
    }
    return [];
  }

  /// 각 탭에 해당하는 목록을 보여주는 위젯
  Widget _buildTabContent(String tab) {
    List<LostItemModel> filteredItems = _getFilteredItems(tab);
    return LostItemsList(items: filteredItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('잃어버린 물건'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // 알림 아이콘 터치 시 동작 구현
            },
          ),
        ],
      ),
      body: isLoading
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
                        children: _tabs.map((tab) => _buildTabContent(tab)).toList(),
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
                          MaterialPageRoute(builder: (context) => LostItemForm()),
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
