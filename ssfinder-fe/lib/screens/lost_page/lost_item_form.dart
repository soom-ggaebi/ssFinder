import 'package:flutter/material.dart';

import '../../widgets/selects/category_select.dart';
import '../../widgets/selects/color_select.dart';
import '../../widgets/selects/location_select.dart';
import '../../widgets/selects/date_select.dart';

class LostItemForm extends StatefulWidget {
  const LostItemForm({Key? key}) : super(key: key);

  @override
  _LostItemFormState createState() => _LostItemFormState();
}

class _LostItemFormState extends State<LostItemForm> {
  String? _selectedCategory;
  String? _selectedColor;
  String? _selectedLocation;
  String? _selectedDate;

  final TextEditingController _itemNameController = TextEditingController();

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('분실물 등록하기')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목 텍스트
            const Text(
              '어떤 물건을',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Text(
              '잃어버리셨나요?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // 이미지 선택 영역
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            // 품목명 입력 필드
            const Text('품목명'),
            const SizedBox(height: 8),
            TextField(
              controller: _itemNameController,
              maxLines: 1,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 카테고리 선택 영역
            const Text('카테고리'),
            const SizedBox(height: 8),
            _buildSelectionItem(
              value: _selectedCategory ?? '',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => CategorySelect(
                          headerLine1: '잃어버리신 물건의',
                          headerLine2: '종류를 알려주세요!',
                        ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _selectedCategory = result;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // 색상 선택 영역
            const Text('색상'),
            const SizedBox(height: 8),
            _buildSelectionItem(
              value: _selectedColor ?? '',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => ColorSelect(
                          headerLine1: '잃어버리신 물건의',
                          headerLine2: '색상을 알려주세요!',
                        ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _selectedColor = result;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // 분실 장소 선택 영역
            const Text('분실장소'),
            const SizedBox(height: 8),
            _buildSelectionItem(
              value: _selectedLocation ?? '',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LocationSelect()),
                );
                if (result != null) {
                  setState(() {
                    _selectedLocation = result;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // 분실 일자 선택 영역
            const Text('분실일자'),
            const SizedBox(height: 8),
            _buildSelectionItem(
              value: _selectedDate ?? '',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => DateSelect(
                          headerLine1: '물건을 잃어버리신',
                          headerLine2: '날짜를 알려주세요!',
                          isRangeSelection: true,
                        ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _selectedDate = result;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

            // 작성 완료 버튼
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // 작성 완료 시 처리 로직
              },
              child: const Text('작성 완료'),
            ),
          ],
        ),
      ),
    );
  }
}

/// 선택 항목 위젯 생성 함수
Widget _buildSelectionItem({
  required String value,
  required VoidCallback onTap,
}) {
  return Container(
    height: 50,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    ),
  );
}
