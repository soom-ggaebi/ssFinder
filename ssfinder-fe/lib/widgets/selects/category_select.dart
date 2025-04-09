import 'package:flutter/material.dart';

class CategorySelect extends StatefulWidget {
  final String headerLine1;
  final String headerLine2;

  const CategorySelect({
    Key? key,
    required this.headerLine1,
    required this.headerLine2,
  }) : super(key: key);

  @override
  _CategorySelectState createState() => _CategorySelectState();
}

class _CategorySelectState extends State<CategorySelect> {
  final List<Map<String, dynamic>> categories = [
    {
      'label': '가방',
      'icon': Icons.shopping_bag,
      'subItems': ['전체', '여성용가방', '남성용가방', '기타가방'],
    },
    {
      'label': '귀금속',
      'icon': Icons.star,
      'subItems': ['전체', '반지', '목걸이', '귀걸이', '시계', '기타'],
    },
    {
      'label': '도서용품',
      'icon': Icons.menu_book,
      'subItems': ['전체', '학습서적', '소설', '컴퓨터서적', '만화책', '기타서적'],
    },
    {
      'label': '서류',
      'icon': Icons.directions_walk,
      'subItems': ['전체', '서류', '기타물품'],
    },
    {
      'label': '산업용품',
      'icon': Icons.build,
      'subItems': ['전체', '기타물품'],
    },
    {
      'label': '쇼핑백',
      'icon': Icons.shopping_bag,
      'subItems': ['전체', '쇼핑백'],
    },
    {
      'label': '스포츠용품',
      'icon': Icons.sports_soccer,
      'subItems': ['전체', '스포츠용품'],
    },
    {
      'label': '악기',
      'icon': Icons.music_note,
      'subItems': ['전체', '건반악기', '관악기', '타악기', '현악기', '기타악기'],
    },
    {
      'label': '유가증권',
      'icon': Icons.money,
      'subItems': ['전체', '어음', '상품권', '채권', '기타'],
    },
    {
      'label': '의류',
      'icon': Icons.checkroom,
      'subItems': ['전체', '여성의류', '남성의류', '아기의류', '모자', '신발', '기타의류'],
    },
    {
      'label': '자동차',
      'icon': Icons.directions_car,
      'subItems': ['전체', '자동차열쇠', '네비게이션', '번호판', '기타'],
    },
    {
      'label': '전자기기',
      'icon': Icons.devices_other,
      'subItems': ['전체', '태블릿', '스마트워치', '무선이어폰', '카메라', '기타용품'],
    },
    {
      'label': '지갑',
      'icon': Icons.account_balance_wallet,
      'subItems': ['전체', '여성용 지갑', '남성용 지갑', '기타 지갑'],
    },
    {
      'label': '증명서',
      'icon': Icons.work,
      'subItems': ['전체', '신분증', '면허증', '여권', '기타'],
    },
    {
      'label': '컴퓨터',
      'icon': Icons.computer,
      'subItems': ['전체', '삼성노트북', 'LG노트북', '애플노트북', '기타'],
    },
    {
      'label': '카드',
      'icon': Icons.credit_card,
      'subItems': ['전체', '신용(체크)카드', '일반카드', '교통카드', '기타카드'],
    },
    {
      'label': '현금',
      'icon': Icons.attach_money,
      'subItems': ['전체', '현금', '수표', '외화', '기타'],
    },
    {
      'label': '휴대폰',
      'icon': Icons.phone_iphone,
      'subItems': ['전체', '삼성휴대폰', 'LG휴대폰', '아이폰', '기타휴대폰', '기타통신기기'],
    },
    {
      'label': '기타물품',
      'icon': Icons.more_horiz,
      'subItems': ['전체', '안경', '선글라스', '매장문화재', '기타'],
    },
    {
      'label': '유류품',
      'icon': Icons.local_gas_station,
      'subItems': ['전체', '무인공항유루품', '유류품'],
    },
  ];

  int? _selectedCategoryIndex;

  String? _selectedSubItem;

  @override
  Widget build(BuildContext context) {
    const int columns = 4;
    final int numRows = (categories.length / columns).ceil();
    final double screenWidth = MediaQuery.of(context).size.width;
    final double itemWidth = (screenWidth - 32 - (columns - 1) * 8) / columns;

    List<Widget> rows = [];

    for (int row = 0; row < numRows; row++) {
      List<Widget> rowItems = [];
      for (int col = 0; col < columns; col++) {
        int index = row * columns + col;
        if (index >= categories.length) break;

        final category = categories[index];
        final bool isSelected = (index == _selectedCategoryIndex);

        rowItems.add(
          GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedCategoryIndex = null;
                  _selectedSubItem = null;
                } else {
                  _selectedCategoryIndex = index;
                  _selectedSubItem = null;
                }
              });
            },
            child: Container(
              width: itemWidth,
              height: 90,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'],
                    size: 28,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category['label'],
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }
      rows.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rowItems,
        ),
      );

      bool rowHasSelected = false;
      int? selectedIndex;
      for (int col = 0; col < columns; col++) {
        int index = row * columns + col;
        if (index >= categories.length) break;
        if (index == _selectedCategoryIndex) {
          rowHasSelected = true;
          selectedIndex = index;
          break;
        }
      }
      if (rowHasSelected && selectedIndex != null) {
        final selectedCategory = categories[selectedIndex];
        rows.add(
          Container(
            width: screenWidth - 32,
            margin: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  (selectedCategory['subItems'] as List<String>).map((sub) {
                final bool isSubSelected = (sub == _selectedSubItem);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSubItem = sub;
                    });
                  },
                  child: Container(
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSubSelected ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sub,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSubSelected ? Colors.white : Colors.black,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '카테고리 선택',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        widget.headerLine1,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        widget.headerLine2,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ...rows,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 선택 완료 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (_selectedCategoryIndex == null || _selectedSubItem == null)
                    ? null
                    : () {
                        final selectedCategory =
                            categories[_selectedCategoryIndex!]['label'];
                        String result;
                        String categoryId;
                        if (_selectedSubItem == '전체') {
                          result = selectedCategory;
                          categoryId = selectedCategory;
                        } else {
                          result = '$selectedCategory > $_selectedSubItem';
                          categoryId = _selectedSubItem!;
                        }
                        Navigator.pop(context, {
                          'category': result,
                          'categoryId': categoryId,
                        });
                      },
                child: const Text('현재 카테고리로 설정'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
