import 'package:flutter/material.dart';

class DateSelect extends StatefulWidget {
  final String headerLine1;
  final String headerLine2;

  const DateSelect({
    Key? key,
    required this.headerLine1,
    required this.headerLine2,
  }) : super(key: key);

  @override
  _DateSelectState createState() => _DateSelectState();
}

class _DateSelectState extends State<DateSelect> {
  // 단일 날짜 선택용 변수
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
    // 초기 선택일은 오늘 날짜로 설정
    _selectedDay = now.day;
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
      // 달을 바꿀 때 선택 초기화
      _selectedDay = null;
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
      // 달을 바꿀 때 선택 초기화
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '습득일자 선택',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),
              // 상단 헤더 문구
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
              // 연도, 월 이동 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _goToPreviousMonth,
                  ),
                  Text(
                    '$_focusedYear년 $_focusedMonth월',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _goToNextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 요일 라벨 (일~토)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children:
                    ['일', '월', '화', '수', '목', '금', '토']
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
              // 날짜 그리드
              Expanded(
                child: GridView.builder(
                  itemCount: daysInMonth,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7, // 7칸 = 일~토
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final dayNumber = index + 1;
                    // 단일 날짜 선택 시 현재 선택된 날짜 확인
                    bool isSelected = _selectedDay == dayNumber;
                    
                    bool isAfterToday = DateTime(_focusedYear, _focusedMonth, dayNumber).isAfter(now);

                    final BoxDecoration boxDecoration;
                    if (isSelected) {
                      boxDecoration = const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      );
                    } else {
                      boxDecoration = const BoxDecoration(
                        color: Colors.transparent,
                      );
                    }

                    return GestureDetector(
                      onTap: isAfterToday
                        ? null
                        : () {
                            setState(() {
                              _selectedDay = dayNumber;
                            });
                          },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: boxDecoration,
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              color: isAfterToday
                                ? Colors.grey
                                : isSelected
                                    ? Colors.white
                                    : Colors.black,
                            fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 선택된 날짜 표시 영역
              if (_selectedDay != null)
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('습득한 날이', style: TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
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
                      const SizedBox(height: 8),
                      const Text('맞으신가요?', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              // "현재 날짜로 설정" 버튼
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
                  final localDate = DateTime(
                    _focusedYear,
                    _focusedMonth,
                    _selectedDay!,
                  );

                  Navigator.pop(context, localDate);
                },
                child: const Text('현재 날짜로 설정'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
