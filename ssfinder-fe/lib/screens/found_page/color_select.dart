import 'package:flutter/material.dart';

class ColorSelect extends StatefulWidget {
  @override
  _ColorSelectState createState() => _ColorSelectState();
}

class _ColorSelectState extends State<ColorSelect> {
  final List<Map<String, dynamic>> colorOptions = [
    {'color': Colors.black, 'label': '검정색'},
    {'color': Colors.white, 'label': '흰색'},
    {'color': Colors.grey, 'label': '회색'},
    {'color': Color.fromARGB(255, 238, 217, 174), 'label': '베이지'},
    {'color': Colors.brown, 'label': '갈색'},
    {'color': Colors.red, 'label': '빨간색'},
    {'color': Colors.orange, 'label': '주황색'},
    {'color': Colors.yellow, 'label': '노란색'},
    {'color': Colors.green, 'label': '초록색'},
    {'color': Colors.blue, 'label': '하늘색'},
    {'color': Color.fromARGB(255, 0, 0, 139), 'label': '남색'},
    {'color': Colors.purple, 'label': '보라색'},
    {'color': Colors.pink, 'label': '분홍색'},
    {'color': Color(0xFFAB82FF), 'label': '보라계열'},
    {'color': Colors.transparent, 'label': '기타'},
  ];

  // 현재 선택된 색상의 라벨
  String? _selectedColorLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('색상 선택')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            Text(
              '물건의 색상을',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '알려주세요!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),

            // 색상 그리드
            Expanded(
              child: GridView.builder(
                itemCount: colorOptions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 한 줄에 4개씩
                  mainAxisSpacing: 12, // 세로 간격
                  crossAxisSpacing: 12, // 가로 간격
                  childAspectRatio: 0.75, // 아이템의 가로세로 비율 (원하는 대로 조정)
                ),
                itemBuilder: (context, index) {
                  final colorOption = colorOptions[index];
                  final label = colorOption['label'] as String;
                  final colorValue = colorOption['color'] as Color;

                  // 선택 여부 확인
                  final isSelected = (label == _selectedColorLabel);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColorLabel = label;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 원형 색상 박스
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorValue,
                            border:
                                isSelected
                                    ? Border.all(color: Colors.blue, width: 3)
                                    : null,
                          ),
                        ),
                        SizedBox(height: 8),
                        // 색상 라벨
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            color: isSelected ? Colors.blue : Colors.black,
                            fontWeight:
                                isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 현재 색상으로 설정 버튼
            SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed:
                  _selectedColorLabel == null
                      ? null
                      : () {
                        Navigator.pop(context, _selectedColorLabel);
                      },
              child: Text('현재 색상으로 설정'),
            ),
          ],
        ),
      ),
    );
  }
}
