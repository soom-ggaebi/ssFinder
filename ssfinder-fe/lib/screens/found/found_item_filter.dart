import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // DateTime 포맷팅을 위해 추가
import 'package:sumsumfinder/widgets/selects/category_select.dart';
import 'package:sumsumfinder/widgets/selects/color_select.dart';
// 습득 장소 선택 위젯 제거: import 'package:sumsumfinder/widgets/selects/location_select.dart';
import 'package:sumsumfinder/widgets/selects/date_select.dart';

class FilterPage extends StatefulWidget {
  // FoundPage에서 전달한 초기 필터 값
  // 예를 들어, { 'status': 'ALL', 'foundDate': '2025-04-08', 'majorCategory': '전자기기', 'minorCategory': '스마트폰', 'color': '검정색', 'type': '숨숨파인더' }
  final Map<String, dynamic> initialFilter;
  const FilterPage({Key? key, required this.initialFilter}) : super(key: key);

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  /// 상태 선택 (전체, 보관중, 전달완료) — UI에서는 한글 값 사용
  String _selectedState = '전체';

  /// 보관 장소 선택 (전체, 숨숨파인더, 경찰청)
  String _storageLocation = '전체';

  /// 습득 일자 선택 – 화면에는 "YYYY년 M월 d일" 형식으로 표시, 내부적으로는 DateTime 객체로 관리
  DateTime? _foundDate;

  /// 카테고리 선택 (예: "전자기기 > 스마트폰")
  String? _selectedCategory;

  /// 색상 선택
  String? _selectedColor;

  // 상태 매핑 함수: UI 한글 값을 API용 문자열로 변경
  String _mapStatus(String state) {
    switch (state) {
      case '전체':
        return 'ALL';
      case '보관중':
        return 'STORED';
      case '전달완료':
        return 'RECEIVED';
      default:
        return 'ALL';
    }
  }

  // 보관 장소(타입) 매핑 함수
  String _mapStorage(String storage) {
    switch (storage) {
      case '전체':
        return '전체';
      case '숨숨파인더':
        return '숨숨파인더';
      case '경찰청':
        return '경찰청';
      default:
        return '전체';
    }
  }

  // 카테고리 문자열 분리 함수: "A > B" 형식이면 A는 majorCategory, B는 minorCategory로 반환
  Map<String, String> _splitCategory(String? category) {
    if (category == null || category.trim().isEmpty) {
      return {'majorCategory': 'null', 'minorCategory': 'null'};
    }
    final parts = category.split(' > ');
    if (parts.length >= 2) {
      return {
        'majorCategory': parts[0].trim(),
        'minorCategory': parts[1].trim(),
      };
    } else {
      return {'majorCategory': category.trim(), 'minorCategory': 'null'};
    }
  }

  @override
  void initState() {
    super.initState();
    // FoundPage에서 전달한 초기 필터 값을 기반으로 UI 초기화

    // [상태] – API 값 (예: 'ALL')을 UI 한글 값으로 매핑
    String status = widget.initialFilter['status'] ?? 'ALL';
    switch (status) {
      case 'ALL':
        _selectedState = '전체';
        break;
      case 'STORED':
        _selectedState = '보관중';
        break;
      case 'RECEIVED':
        _selectedState = '전달완료';
        break;
      default:
        _selectedState = '전체';
    }

    // [보관 장소] – API의 'type' 값으로 설정 (숨숨파인더 또는 경찰청이면 그대로, 그 외에는 "전체")
    String type = widget.initialFilter['type'] ?? '전체';
    if (type == '숨숨파인더' || type == '경찰청') {
      _storageLocation = type;
    } else {
      _storageLocation = '전체';
    }

    // [습득 일자] – API 형식("yyyy-MM-dd")을 DateTime으로 파싱한 후, UI에 표시할 때 포맷팅
    String apiFoundDate = widget.initialFilter['foundDate'] ?? 'null';
    if (apiFoundDate != 'null' && apiFoundDate.trim().isNotEmpty) {
      try {
        _foundDate = DateTime.parse(apiFoundDate);
      } catch (e) {
        _foundDate = null;
      }
    } else {
      _foundDate = null;
    }

    // [카테고리] – majorCategory와 minorCategory가 모두 존재하면 결합 ("A > B")하여 UI에 표시
    String major = widget.initialFilter['majorCategory'] ?? 'null';
    String minor = widget.initialFilter['minorCategory'] ?? 'null';
    if (major != 'null' && minor != 'null') {
      _selectedCategory = '$major > $minor';
    } else {
      _selectedCategory = '';
    }

    // [색상]
    _selectedColor = widget.initialFilter['color'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    // _foundDate가 DateTime일 경우, 화면 표시에 사용할 문자열 생성 (예: "2025년 4월 8일")
    String foundDateDisplay =
        _foundDate != null ? DateFormat('yyyy년 M월 d일').format(_foundDate!) : '';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildLabel('상태'),
                      const SizedBox(height: 8),
                      _buildStateSelector(),
                      const SizedBox(height: 16),
                      _buildLabel('보관 장소'),
                      const SizedBox(height: 8),
                      _buildStorageLocationSelector(),
                      const SizedBox(height: 16),
                      _buildLabel('습득 일자'),
                      const SizedBox(height: 8),
                      // foundDateDisplay 문자열을 화면에 표시
                      _buildSelectionItem(
                        value: foundDateDisplay,
                        hintText: '습득 일자를 선택하세요',
                        onTap: () async {
                          // DateSelect가 DateTime 객체를 반환하도록 구성
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => DateSelect(
                                    headerLine1: '찾으시는',
                                    headerLine2: '날짜를 알려주세요!',
                                  ),
                            ),
                          );
                          if (result != null && result is DateTime) {
                            setState(() {
                              _foundDate = result;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('카테고리'),
                      const SizedBox(height: 8),
                      _buildSelectionItem(
                        value: _selectedCategory ?? '',
                        hintText: '카테고리를 선택하세요',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => CategorySelect(
                                    headerLine1: '찾으시는 물건의',
                                    headerLine2: '종류를 알려주세요!',
                                  ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              // CategorySelect에서 'category' 키의 값 사용 (문자열)
                              _selectedCategory = result['category'].toString();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('색상'),
                      const SizedBox(height: 8),
                      _buildSelectionItem(
                        value: _selectedColor ?? '',
                        hintText: '색상을 선택하세요',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (_) => ColorSelect(
                                    headerLine1: '찾으시는 물건의',
                                    headerLine2: '색상을 알려주세요!',
                                  ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _selectedColor = result.toString();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                  // [상태] UI 한글 값을 API용 문자열로 변환
                  final apiStatus = _mapStatus(_selectedState);
                  // [보관 장소] API용으로 변환
                  final apiType = _mapStorage(_storageLocation);
                  // [습득 일자] DateTime을 "yyyy-MM-dd" 형식으로 포맷팅
                  String apiFoundAt =
                      _foundDate != null
                          ? DateFormat('yyyy-MM-dd').format(_foundDate!)
                          : 'null';

                  // 반환할 Map은 FoundPage에서 기대하는 키로 구성
                  Navigator.pop(context, {
                    'state': apiStatus, // 예: "ALL", "STORED", "RECEIVED"
                    'type': apiType, // 예: "숨숨파인더", "경찰청", "all(숨숨파인더/경찰청/all)"
                    'foundDate': apiFoundAt, // 예: "2025-04-08"
                    'category': _selectedCategory ?? 'null', // 예: "전자기기 > 스마트폰"
                    'color': _selectedColor?.toString() ?? 'null',
                  });
                },
                child: const Text('필터 적용'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 상단 헤더 위젯
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: 48),
          Expanded(
            child: Center(
              child: Text(
                '검색 필터',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// 상태 선택 위젯 (전체, 보관중, 전달완료)
  Widget _buildStateSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStateButton('전체', isFor: 'state'),
          _buildStateButton('보관중', isFor: 'state'),
          _buildStateButton('전달완료', isFor: 'state'),
        ],
      ),
    );
  }

  /// 보관 장소 선택 위젯 (전체, 숨숨파인더, 경찰청)
  Widget _buildStorageLocationSelector() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStateButton('전체', isFor: 'storage'),
          _buildStateButton('숨숨파인더', isFor: 'storage'),
          _buildStateButton('경찰청', isFor: 'storage'),
        ],
      ),
    );
  }

  /// 공통 선택 버튼 위젯 (상태/보관 장소)
  Widget _buildStateButton(String label, {required String isFor}) {
    bool isSelected = false;
    if (isFor == 'state') {
      isSelected = (label == _selectedState);
    } else if (isFor == 'storage') {
      isSelected = (label == _storageLocation);
    }
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            if (isFor == 'state') {
              _selectedState = label;
            } else if (isFor == 'storage') {
              _storageLocation = label;
            }
          });
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// 라벨 텍스트 위젯
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  /// 선택형 항목 위젯 (InkWell + 아이콘)
  Widget _buildSelectionItem({
    required String value,
    required String hintText,
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.isEmpty ? hintText : value,
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
}
