import 'package:flutter/material.dart';

import '../../widgets/selects/category_select.dart';
import '../../widgets/selects/color_select.dart';
import '../../widgets/selects/location_select.dart';
import '../../widgets/selects/date_select.dart';

class FoundItemForm extends StatefulWidget {
  @override
  _FoundItemFormState createState() => _FoundItemFormState();
}

class _FoundItemFormState extends State<FoundItemForm> {
  String? _selectedCategory; // 카테고리
  String? _selectedColor; // 색상
  String? _selectedLocation; // 습득 장소
  String? _selectedDate; // 습득 일자

  TextEditingController _itemNameController = TextEditingController(); // 품목명
  TextEditingController _detailController = TextEditingController(); // 상세 설명

  @override
  void dispose() {
    _itemNameController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('습득물 등록하기')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '어떤 물건을',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              '주우셨나요?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),

            // 이미지 선택
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
            SizedBox(height: 20),

            // 품목명 입력
            Text('품목명'),
            SizedBox(height: 8),
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
            SizedBox(height: 20),

            // 카테고리 선택
            Text('카테고리'),
            SizedBox(height: 8),
            _buildSelectionItem(
              value: _selectedCategory ?? '',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CategorySelect()),
                );
                if (result != null) {
                  setState(() {
                    _selectedCategory = result;
                  });
                }
              },
            ),
            SizedBox(height: 20),

            // 색상 선택
            Text('색상'),
            SizedBox(height: 8),
            _buildSelectionItem(
              value: _selectedColor ?? '',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ColorSelect()),
                );
                if (result != null) {
                  setState(() {
                    _selectedColor = result;
                  });
                }
              },
            ),
            SizedBox(height: 20),

            // 습득 장소 선택
            Text('습득장소'),
            SizedBox(height: 8),
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
            SizedBox(height: 20),

            // 습득 일자 선택
            Text('습득일자'),
            SizedBox(height: 8),
            _buildSelectionItem(
              value: _selectedDate ?? '',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DateSelect()),
                );
                if (result != null) {
                  setState(() {
                    _selectedDate = result;
                  });
                }
              },
            ),
            SizedBox(height: 20),

            // 상세 설명 입력
            Text('상세설명'),
            SizedBox(height: 8),
            TextField(
              controller: _detailController,
              maxLines: 5,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 20),

            // 작성 완료
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Navigator.pop(context);
              },
              child: Text('작성 완료'),
            ),
          ],
        ),
      ),
    );
  }
}

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
            SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    ),
  );
}
