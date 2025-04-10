import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_items_model.dart';
import 'package:sumsumfinder/services/found_items_api_service.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'found_items_list.dart';
import '../../../screens/found/found_item_form.dart';

class FoundPage extends StatefulWidget {
  const FoundPage({Key? key}) : super(key: key);

  @override
  _FoundPageState createState() => _FoundPageState();
}

class _FoundPageState extends State<FoundPage>
    with SingleTickerProviderStateMixin {
  final FoundItemsApiService _apiService = FoundItemsApiService();
  List<FoundItemListModel> _foundItems = [];
  bool isLoading = true;

  // 탭 목록: 전체, 찾는 중, 찾음
  final List<String> _tabs = ['전체', '찾는 중', '찾음'];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadFoundItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFoundItems() async {
    try {
      final response = await _apiService.getMyFoundItems();
      final List<dynamic> itemsJson =
          response['data']['content'] as List<dynamic>;
      print('#### Found Items: $itemsJson');

      final items =
          itemsJson
              .map(
                (item) =>
                    FoundItemListModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();

      setState(() {
        _foundItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      print('Error: $e');
    }
  }

  List<FoundItemListModel> _getFilteredItems(String tab) {
    if (tab == '전체') {
      return _foundItems;
    } else if (tab == '찾는 중') {
      return _foundItems.where((item) => item.status == "STORED").toList();
    } else if (tab == '찾음') {
      return _foundItems.where((item) => item.status == "RECEIVED").toList();
    }
    return [];
  }

  void _handleItemStatusChanged(int itemId, String newStatus) {
    setState(() {
      for (int i = 0; i < _foundItems.length; i++) {
        if (_foundItems[i].id == itemId) {
          _foundItems[i] = _foundItems[i].copyWith(status: newStatus);
          break;
        }
      }
    });
  }

  Widget _buildTabContent(String tab) {
    final filteredItems = _getFilteredItems(tab);
    return FoundItemsList(
      items: filteredItems,
      onItemStatusChanged: _handleItemStatusChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '나의 습득물', isFromBottomNav: true),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                children: [
                  Column(
                    children: [
                      Container(
                        color: Colors.white,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue,
                          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
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
                  // 습득물 등록 버튼
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
                              builder: (context) => const FoundItemForm(),
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
