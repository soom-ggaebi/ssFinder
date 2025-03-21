import 'package:flutter/material.dart';

class DateSelect extends StatefulWidget {
  @override
  _DateSelectState createState() => _DateSelectState();
}

class _DateSelectState extends State<DateSelect> {
  // 기본값으로 2025년 3월을 예시로 설정
  int _focusedYear = 2025;
  int _focusedMonth = 3;

  // 사용자가 선택한 '일(day)'
  int? _selectedDay;

  /// 현재 화면에 표시되는 달의 총 일수
  int get daysInMonth {
    // 예: 3월이면 (3 + 1) -> 4월의 0일 = 3월 말일
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
      _selectedDay = null; // 다른 달로 넘어갈 때, 선택된 날짜 초기화
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
      _selectedDay = null; // 다른 달로 넘어갈 때, 선택된 날짜 초기화
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('습득일자 선택')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              '물건을 습득하신',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              '날짜를 알려주세요!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: _goToPreviousMonth,
                ),
                Text(
                  '$_focusedYear년 $_focusedMonth월',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: _goToNextMonth,
                ),
              ],
            ),
            SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  ['일', '월', '화', '수', '목', '금', '토']
                      .map(
                        (day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
            SizedBox(height: 8),

            Expanded(
              child: GridView.builder(
                itemCount: daysInMonth,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                      margin: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
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

            SizedBox(height: 16),

            if (_selectedDay != null) ...[
              Text('습득한 날이', style: TextStyle(fontSize: 16)),
              Text(
                '$_focusedYear년 $_focusedMonth월 $_selectedDay일',
                style: TextStyle(fontSize: 16),
              ),
              Text('맞으신가요?', style: TextStyle(fontSize: 16)),
            ],

            SizedBox(height: 32),

            // "현재 날짜로 설정" 버튼
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
                  _selectedDay == null
                      ? null
                      : () {
                        final result =
                            '$_focusedYear년 $_focusedMonth월 $_selectedDay일';
                        Navigator.pop(context, result);
                      },
              child: Text('현재 날짜로 설정'),
            ),
          ],
        ),
      ),
    );
  }
}
