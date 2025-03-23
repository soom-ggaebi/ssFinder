import 'package:flutter/material.dart';

class ColorSelect extends StatefulWidget {
  @override
  _ColorSelectState createState() => _ColorSelectState();
}

class _ColorSelectState extends State<ColorSelect> {
  final List<Map<String, dynamic>> colorOptions = [
    {'color': Colors.black, 'label': '검정색'},
    {'color': Colors.white, 'label': '흰색'},
    {'color': const Color(0xFFCCCCCC), 'label': '회색'},
    {'color': const Color(0xFFE6C9A8), 'label': '베이지'},
    {'color': const Color(0xFFA67B5B), 'label': '갈색'},
    {'color': const Color(0xFFCE464B), 'label': '빨간색'},
    {'color': const Color(0xFFFFAD60), 'label': '주황색'},
    {'color': const Color(0xFFFFDD65), 'label': '노란색'},
    {'color': const Color(0xFF7FD17F), 'label': '초록색'},
    {'color': const Color(0xFF80CCFF), 'label': '하늘색'},
    {'color': const Color(0xFF5975FF), 'label': '파란색'},
    {'color': const Color(0xFF2B298D), 'label': '남색'},
    {'color': const Color(0xFFB771DF), 'label': '보라색'},
    {'color': const Color(0xFFFF9FC0), 'label': '분홍색'},
    {'color': Colors.transparent, 'label': '기타'},
  ];

  // 현재 선택된 색상의 라벨
  String? _selectedColorLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('색상 선택')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // 상단 스크롤 영역: 제목 텍스트와 색상 그리드가 포함됨
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Text(
                        '주우신 물건의',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        '색상을 알려주세요!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: colorOptions.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 한 줄에 3개씩 표시
                            mainAxisSpacing: 12, // 세로 간격
                            crossAxisSpacing: 12, // 가로 간격
                            childAspectRatio: 1, // 아이템의 가로세로 비율
                          ),
                          itemBuilder: (context, index) {
                            final colorOption = colorOptions[index];
                            final label = colorOption['label'] as String;
                            final colorValue = colorOption['color'] as Color;
                            final bool isSelected =
                                (label == _selectedColorLabel);

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedColorLabel = label;
                                });
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 선택된 경우에는 무지개 그라데이션 테두리 적용
                                  isSelected
                                      ? Container(
                                          width: 100,
                                          height: 75,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.red,
                                                Colors.orange,
                                                Colors.yellow,
                                                Colors.green,
                                                Colors.blue,
                                                Colors.indigo,
                                                Colors.purple,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(50.0),
                                          ),
                                          padding: const EdgeInsets.all(5), // 테두리 두께
                                          child: Container(
                                            decoration: BoxDecoration(
                                              // '기타' 옵션인 경우 그라데이션 적용, 그 외에는 기존 색상 적용
                                              color: label == '기타'
                                                  ? null
                                                  : colorValue,
                                              gradient: label == '기타'
                                                  ? const LinearGradient(
                                                      colors: [
                                                        Colors.red,
                                                        Colors.orange,
                                                        Colors.yellow,
                                                        Colors.green,
                                                        Colors.blue,
                                                        Colors.indigo,
                                                        Colors.purple,
                                                      ],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    )
                                                  : null,
                                              borderRadius:
                                                  BorderRadius.circular(45.0),
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: 100,
                                          height: 75,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            // '기타' 옵션은 그라데이션 적용
                                            color: label == '기타'
                                                ? null
                                                : colorValue,
                                            gradient: label == '기타'
                                                ? const LinearGradient(
                                                    colors: [
                                                      Colors.red,
                                                      Colors.orange,
                                                      Colors.yellow,
                                                      Colors.green,
                                                      Colors.blue,
                                                      Colors.indigo,
                                                      Colors.purple,
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : null,
                                            borderRadius:
                                                BorderRadius.circular(50.0),
                                          ),
                                        ),
                                  const SizedBox(height: 8),
                                  Text(
                                    label,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 하단 "현재 색상으로 설정" 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _selectedColorLabel == null
                    ? null
                    : () {
                        Navigator.pop(context, _selectedColorLabel);
                      },
                child: const Text('현재 색상으로 설정'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
