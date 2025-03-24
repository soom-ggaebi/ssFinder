import 'package:flutter/material.dart';

class DateSelect extends StatefulWidget {
  final String headerLine1;
  final String headerLine2;
  final bool isRangeSelection; // false: 단일 날짜, true: 날짜 범위 선택

  const DateSelect({
    Key? key,
    required this.headerLine1,
    required this.headerLine2,
    this.isRangeSelection = false,
  }) : super(key: key);

  @override
  _DateSelectState createState() => _DateSelectState();
}

class _DateSelectState extends State<DateSelect> {
  // 단일 날짜 선택용 변수
  int? _selectedDay;

  // 범위 선택용 변수
  DateTime? _selectedStart;
  DateTime? _selectedEnd;

  // 현재 포커스가 맞춰진 연도와 월 (기본값: 현재 날짜)
  late int _focusedYear;
  late int _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedYear = now.year;
    _focusedMonth = now.month;

    if (!widget.isRangeSelection) {
      // 단일 선택일 경우, 초기 선택일은 오늘 날짜
      _selectedDay = now.day;
    } else {
      // 범위 선택 모드
      _selectedStart = null;
      _selectedEnd = null;
    }
  }

  /// 현재 달의 총 일수
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
      // 달을 바꿀 때 선택 초기화 로직
      if (widget.isRangeSelection) {
        _selectedStart = null;
        _selectedEnd = null;
      } else {
        _selectedDay = null;
      }
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
      // 달을 바꿀 때 선택 초기화 로직
      if (widget.isRangeSelection) {
        _selectedStart = null;
        _selectedEnd = null;
      } else {
        _selectedDay = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isRangeSelection ? '분실기간 선택' : '습득일자 선택'),
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
              // 요일 라벨
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
                    final currentDate = DateTime(
                      _focusedYear,
                      _focusedMonth,
                      dayNumber,
                    );

                    // [1] 각 날짜별 상태 판별
                    bool isRangeStart = false;
                    bool isRangeEnd = false;
                    bool isInRange = false;

                    if (widget.isRangeSelection) {
                      // 범위 선택 모드
                      if (_selectedStart != null && _selectedEnd != null) {
                        // 1) start ~ end 범위 내에 있으면 inRange
                        if (!currentDate.isBefore(_selectedStart!) &&
                            !currentDate.isAfter(_selectedEnd!)) {
                          isInRange = true;
                        }
                        // 2) 정확히 start 혹은 end 날짜인지
                        if (currentDate.isAtSameMomentAs(_selectedStart!)) {
                          isRangeStart = true;
                        }
                        if (currentDate.isAtSameMomentAs(_selectedEnd!)) {
                          isRangeEnd = true;
                        }
                      } else if (_selectedStart != null &&
                          _selectedEnd == null) {
                        // 시작일만 선택된 상태
                        if (currentDate.isAtSameMomentAs(_selectedStart!)) {
                          isRangeStart = true;
                        }
                      }
                    } else {
                      // 단일 날짜 모드
                      if (_selectedDay == dayNumber) {
                        isRangeStart = true; // 시작과 끝이 동일
                        isRangeEnd = true;
                        isInRange = true;
                      }
                    }

                    // [2] BoxDecoration 결정
                    final BoxDecoration boxDecoration;
                    if (isRangeStart && isRangeEnd) {
                      // 시작일과 종료일이 같거나 단일 날짜 모드
                      boxDecoration = const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      );
                    } else if (isRangeStart) {
                      // 범위 시작일
                      boxDecoration = const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      );
                    } else if (isRangeEnd) {
                      // 범위 종료일
                      boxDecoration = const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      );
                    } else if (isInRange) {
                      // 시작일과 종료일 사이 날짜
                      boxDecoration = BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                      );
                    } else {
                      // 선택되지 않은 날짜
                      boxDecoration = const BoxDecoration(
                        color: Colors.transparent,
                      );
                    }

                    // [3] onTap 로직 (범위 선택 or 단일 날짜)
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (!widget.isRangeSelection) {
                            // 단일 날짜 선택
                            _selectedDay = dayNumber;
                          } else {
                            // 범위 선택
                            if (_selectedStart == null ||
                                (_selectedStart != null &&
                                    _selectedEnd != null)) {
                              // 새 범위 시작
                              _selectedStart = currentDate;
                              _selectedEnd = null;
                            } else {
                              // _selectedStart만 선택된 상태
                              if (currentDate.isBefore(_selectedStart!)) {
                                // 시작일보다 이전 날짜를 누르면 시작일 갱신
                                _selectedStart = currentDate;
                              } else {
                                // 시작일 이후 날짜
                                final diff =
                                    currentDate
                                        .difference(_selectedStart!)
                                        .inDays;
                                if (diff <= 6) {
                                  _selectedEnd = currentDate;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('최대 일주일까지만 선택할 수 있습니다.'),
                                    ),
                                  );
                                }
                              }
                            }
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: boxDecoration,
                        child: Center(
                          child: Text(
                            '$dayNumber',
                            style: TextStyle(
                              color:
                                  (isRangeStart || isRangeEnd)
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

              // [4] 선택된 날짜 또는 기간 표시 영역
              if (!widget.isRangeSelection)
                // 단일 날짜 모드
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
                  )
                else
                  const SizedBox.shrink()
              else
              // 범위 선택 모드
              if (_selectedStart != null)
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        _selectedEnd != null
                            ? [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    '분실하신 기간이 ',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                                      '$_focusedYear년 $_focusedMonth월 ${_selectedStart!.day}일',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    ' 부터',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                                      '$_focusedYear년 $_focusedMonth월 ${_selectedEnd!.day}일',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const Text(
                                    ' 까지',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '맞으신가요?',
                                style: TextStyle(fontSize: 16),
                              ),
                            ]
                            : [
                              const Text(
                                '시작일이 ',
                                style: TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                                      '$_focusedYear년 $_focusedMonth월 ${_selectedStart!.day}일',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                '선택되었습니다',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                  ),
                )
              else
                const SizedBox.shrink(),

              const SizedBox(height: 16),
              // 단일 날짜 선택이면 "현재 날짜로 설정", 범위 선택이면 "현재 기간으로 설정"
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
                  if (!widget.isRangeSelection) {
                    // 단일 날짜 모드
                    if (_selectedDay != null) {
                      final result =
                          '$_focusedYear년 $_focusedMonth월 $_selectedDay일';
                      Navigator.pop(context, result);
                    }
                  } else {
                    // 범위 선택 모드
                    if (_selectedStart != null && _selectedEnd != null) {
                      final result =
                          '$_focusedYear년 $_focusedMonth월 ${_selectedStart!.day}일'
                          ' ~ '
                          '$_focusedYear년 $_focusedMonth월 ${_selectedEnd!.day}일';
                      Navigator.pop(context, result);
                    }
                  }
                },
                child: Text(
                  widget.isRangeSelection ? '현재 기간으로 설정' : '현재 날짜로 설정',
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
