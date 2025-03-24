import 'package:flutter/material.dart';

class StorageLocation extends StatefulWidget {
  const StorageLocation({Key? key}) : super(key: key);

  @override
  _StorageLocationState createState() => _StorageLocationState();
}

class _StorageLocationState extends State<StorageLocation> {
  // 검색어를 관리하는 TextEditingController
  final TextEditingController _searchController = TextEditingController();

  // 전체 위치 목록 (각 항목은 이름과 전화번호를 포함한 Map)
  final List<Map<String, String>> _locations = [
    {'name': '다이소(분점2호점)', 'phone': '02-03285-6015'},
    {'name': '다이소(분점3호점)', 'phone': '02-03285-6016'},
    {'name': '다이소(분점4호점)', 'phone': '02-03285-6017'},
    {'name': '다이소(분점5호점)', 'phone': '02-03285-6018'},
    {'name': '다이소(분점6호점)', 'phone': '02-03285-6019'},
    {'name': '다이소(분점7호점)', 'phone': '02-03285-6020'},
  ];

  // 검색어에 따라 필터링된 위치 목록
  List<Map<String, String>> _filteredLocations = [];

  // 현재 선택된 항목의 인덱스
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    // 시작 시 전체 위치 목록을 초기화
    _filteredLocations = List.from(_locations);
  }

  /// 검색어에 따라 _locations 목록을 필터링하여 _filteredLocations 업데이트
  void _filterLocations(String query) {
    if (!mounted) return;
    setState(() {
      _filteredLocations =
          query.isEmpty
              ? List.from(_locations)
              : _locations.where((location) {
                final name = location['name'] ?? '';
                return name.contains(query);
              }).toList();
    });
  }

  /// 리스트 항목을 탭했을 때 선택된 인덱스 업데이트
  void _onLocationTap(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  /// 선택 완료 버튼 클릭 시, 선택한 항목의 'name'만 반환하고 이전 화면으로 pop
  void _onConfirm() {
    if (_selectedIndex == null) return;
    final selectedName = _filteredLocations[_selectedIndex!]['name'];
    Navigator.pop(context, selectedName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar로 제목 표시
      appBar: AppBar(
        title: const Text(
          '보관장소 선택',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // 검색 입력 영역
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '위치 검색',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        onChanged: _filterLocations,
                      ),
                    ),
                  ],
                ),
              ),
              // 위치 목록을 보여주는 ListView
              Expanded(
                child: ListView.builder(
                  itemCount: _filteredLocations.length,
                  itemBuilder: (context, index) {
                    final location = _filteredLocations[index];
                    final isSelected = (index == _selectedIndex);
                    return GestureDetector(
                      onTap: () => _onLocationTap(index),
                      child: Container(
                        color:
                            isSelected ? Colors.blue[50] : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(location['phone'] ?? ''),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // 선택 완료 버튼
              ElevatedButton(
                onPressed: _selectedIndex == null ? null : _onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('현재 장소로 설정'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
