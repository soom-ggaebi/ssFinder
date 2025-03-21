import 'package:flutter/material.dart';

import './lost_item_form.dart';

class LostPage extends StatefulWidget {
  @override
  _LostPageState createState() => _LostPageState();
}

class _LostPageState extends State<LostPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // 탭 목록 (전체, 숨은물건, 찾은물건)
  final List<String> _tabs = ['전체', '숨은물건', '찾은물건'];

  // 더미 데이터 (각 항목은 Map 형태)
  final List<Map<String, String>> _items = [
    {
      "품목명": "지갑",
      "카테고리": "패션소품",
      "색상": "검정",
      "분실장소": "서울역",
      "분실일자": "2025-03-10",
      "상세설명": "내부에 신분증과 카드가 들어 있음",
      "상태": "찾은물건",
    },
    {
      "품목명": "우산",
      "카테고리": "생활용품",
      "색상": "회색",
      "분실장소": "버스정류장",
      "분실일자": "2025-03-12",
      "상세설명": "열려 있었고, 독특한 모양을 가짐",
      "상태": "숨은물건",
    },
    {
      "품목명": "핸드폰",
      "카테고리": "전자제품",
      "색상": "은색",
      "분실장소": "카페",
      "분실일자": "2025-03-11",
      "상세설명": "케이스 부착, 화면에 금이 간 상태",
      "상태": "전체",
    },
    {
      "품목명": "열쇠",
      "카테고리": "액세서리",
      "색상": "금속색",
      "분실장소": "공원",
      "분실일자": "2025-03-13",
      "상세설명": "여러 개의 열쇠가 하나의 고리로 연결됨",
      "상태": "찾은물건",
    },
    {
      "품목명": "가방",
      "카테고리": "패션소품",
      "색상": "빨강",
      "분실장소": "도서관",
      "분실일자": "2025-03-14",
      "상세설명": "내부에 노트북이 들어 있었던 큰 가방",
      "상태": "숨은물건",
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 탭에 따른 아이템 필터링 함수
  List<Map<String, String>> _getFilteredItems(String tab) {
    if (tab == '전체') {
      return _items;
    } else if (tab == '숨은물건') {
      return _items.where((item) => item["상태"] == "숨은물건").toList();
    } else if (tab == '찾은물건') {
      return _items.where((item) => item["상태"] == "찾은물건").toList();
    }
    return [];
  }

  // 각 아이템 카드 위젯
  Widget _buildItemCard(Map<String, String> item) {
    bool isFound = item["상태"] == "찾은물건";

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["품목명"] ?? "",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  "${item["카테고리"]} / ${item["색상"]}",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text("분실장소: ${item["분실장소"]}", style: TextStyle(fontSize: 12)),
                SizedBox(height: 4),
                Text("분실일자: ${item["분실일자"]}", style: TextStyle(fontSize: 12)),
                SizedBox(height: 4),
                Text("상세설명: ${item["상세설명"]}", style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          // "찾은물건"인 경우 불투명한 검은색 오버레이
          if (isFound)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 각 탭의 내용을 보여주는 위젯
  Widget _buildTabContent(String tab) {
    List<Map<String, String>> filteredItems = _getFilteredItems(tab);
    return ListView.builder(
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        return _buildItemCard(filteredItems[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('잃어버린 물건'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {
              // 알림 아이콘 누르면 동작 구현
            },
          ),
        ],
      ),
      body: Stack(
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
          Positioned(
            bottom: 20,
            right: 20,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LostItemForm()),
                );
              },
              borderRadius: BorderRadius.circular(8), // 터치 효과를 위한 둥근 모서리
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 20),
                    SizedBox(width: 4),
                    Text(
                      '분실물 등록',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
