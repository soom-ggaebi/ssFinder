import 'package:flutter/material.dart';
// 아래 네 개는 예시로, 실제로 존재하는 Select 페이지들을 import한다고 가정합니다.
import '../../widgets/selects/category_select.dart';
import '../../widgets/selects/color_select.dart';
import '../../widgets/selects/location_select.dart';
import '../../widgets/selects/date_select.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({Key? key}) : super(key: key);

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  /// 상태 (전체, 보관중, 전달완료) 중 하나를 선택
  String _selectedState = '전체';

  /// 보관 장소
  String? _storageLocation;

  /// 습득 장소
  String? _foundLocation;

  /// 습득 일자
  String? _foundDate;

  /// 카테고리
  String? _selectedCategory;

  /// 색상
  String? _selectedColor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단 헤더
            _buildHeader(context),
            // 본문 스크롤 가능 영역
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStateSelector(),
                    const SizedBox(height: 16),

                    _buildLabel('보관 장소'),
                    const SizedBox(height: 8),
                    _buildSelectionItem(
                      value: _storageLocation ?? '',
                      hintText: '보관 장소를 선택하세요',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LocationSelect()),
                        );
                        if (result != null) {
                          setState(() {
                            _storageLocation = result;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('습득 장소'),
                    const SizedBox(height: 8),
                    _buildSelectionItem(
                      value: _foundLocation ?? '',
                      hintText: '습득 장소를 선택하세요',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => LocationSelect()),
                        );
                        if (result != null) {
                          setState(() {
                            _foundLocation = result;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('습득 일자'),
                    const SizedBox(height: 8),
                    _buildSelectionItem(
                      value: _foundDate ?? '',
                      hintText: '습득 일자를 선택하세요',
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DateSelect()),
                        );
                        if (result != null) {
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
                          MaterialPageRoute(builder: (_) => CategorySelect()),
                        );
                        if (result != null) {
                          setState(() {
                            _selectedCategory = result;
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
                          MaterialPageRoute(builder: (_) => ColorSelect()),
                        );
                        if (result != null) {
                          setState(() {
                            _selectedColor = result;
                          });
                        }
                      },
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
                        Navigator.pop(context, {
                          'state': _selectedState,
                          'storageLocation': _storageLocation,
                          'foundLocation': _foundLocation,
                          'foundDate': _foundDate,
                          'category': _selectedCategory,
                          'color': _selectedColor,
                        });
                      },
                      child: const Text('필터 적용'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 상단 헤더
  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          // 닫기 버튼
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// 상태(전체, 보관중, 전달완료)
  Widget _buildStateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStateButton('전체'),
        _buildStateButton('보관중'),
        _buildStateButton('전달완료'),
      ],
    );
  }

  /// 개별 상태 버튼
  Widget _buildStateButton(String label) {
    final bool isSelected = (label == _selectedState);
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedState = label;
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

  /// 라벨 텍스트
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// 선택형 항목 (InkWell + Icon)
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
