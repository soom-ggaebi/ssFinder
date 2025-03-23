import 'package:flutter/material.dart';

class DateSelect extends StatefulWidget {
  @override
  _DateSelectState createState() => _DateSelectState();
}

class _DateSelectState extends State<DateSelect> {
  // 사용자가 선택한 '일'
  int? _selectedDay;

  // 현재 포커스가 맞춰진 연도와 월 (기본값: 현재 날짜)
  late int _focusedYear;
  late int _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedYear = now.year;
    _focusedMonth = now.month;
    _selectedDay = now.day; // 초기 선택일을 현재 날짜로 설정
  }

  /// 현재 달의 총 일수를 계산
  int get daysInMonth {
    return DateTime(_focusedYear, _focusedMonth + 1, 0).day;
  }

  /// 이전 달로 이동
  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth--;
      if (_focusedMonth < 1) {
        _focusedMonth = 12;
        _focusedYear--;
      }
      _selectedDay = null; // 달이 바뀔 때 선택된 날짜 초기화
    });
  }

  /// 다음 달로 이동
  void _goToNextMonth() {
    setState(() {
      _focusedMonth++;
      if (_focusedMonth > 12) {
        _focusedMonth = 1;
        _focusedYear++;
      }
      _selectedDay = null; // 달이 바뀔 때 선택된 날짜 초기화
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('습득일자 선택')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // 상단 텍스트 영역 (세로로 배치)
              const Column(
                children: [
                  Text(
                    '물건을 주우신',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '날짜를 알려주세요!',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                ],
              ),
              // 달 이동 버튼 및 현재 연월 표시
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _goToPreviousMonth,
                  ),
                  Text(
                    '$_focusedYear년 $_focusedMonth월',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _goToNextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 요일 라벨 (가로로 배치)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['일', '월', '화', '수', '목', '금', '토']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              // 날짜 그리드: 남은 공간 전체를 차지하도록 Expanded 사용
              Expanded(
                child: GridView.builder(
                  itemCount: daysInMonth,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final dayNumber = index + 1;
                    final isSelected = (dayNumber == _selectedDay);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = dayNumber;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.transparent,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 선택된 날짜 영역: 고정 높이 Container로 배치 (남은 영역 하단)
              if (_selectedDay != null)
                Container(
                  height: 80,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '습득한 날이',
                        style: TextStyle(fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(50.0),
                        ),
                        child: Text(
                          '$_focusedYear년 $_focusedMonth월 $_selectedDay일',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const Text(
                        '맞으신가요?',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              const SizedBox(height: 32),
              // 하단 "현재 날짜로 설정" 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _selectedDay == null
                    ? null
                    : () {
                        final result =
                            '$_focusedYear년 $_focusedMonth월 $_selectedDay일';
                        Navigator.pop(context, result);
                      },
                child: const Text('현재 날짜로 설정'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
