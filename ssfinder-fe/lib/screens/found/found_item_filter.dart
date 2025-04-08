import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sumsumfinder/widgets/selects/category_select.dart';
import 'package:sumsumfinder/widgets/selects/color_select.dart';
import 'package:sumsumfinder/widgets/selects/date_select.dart';

class FilterPage extends StatefulWidget {
  final Map<String, dynamic> initialFilter;
  const FilterPage({Key? key, required this.initialFilter}) : super(key: key);

  @override
  _FilterPageState createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  String _selectedState = '전체';
  String _storageLocation = '전체';
  DateTime? _foundAt;
  String? _selectedCategory;
  String? _selectedColor;

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

  @override
  void initState() {
    super.initState();

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

    String type = widget.initialFilter['type'] ?? '전체';
    if (type == '숨숨파인더' || type == '경찰청') {
      _storageLocation = type;
    } else {
      _storageLocation = '전체';
    }

    String apifoundAt = widget.initialFilter['foundAt'] ?? '';
    if (apifoundAt != '' && apifoundAt.trim().isNotEmpty) {
      try {
        _foundAt = DateTime.parse(apifoundAt);
      } catch (e) {
        _foundAt = null;
      }
    } else {
      _foundAt = null;
    }

    String major = widget.initialFilter['majorCategory'] ?? '';
    String minor = widget.initialFilter['minorCategory'] ?? '';

    if (major != '' || minor != '') {
      _selectedCategory = major + ' > ' + minor;
    } else {
      _selectedCategory = '';
    }

    _selectedColor = widget.initialFilter['color'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    String foundAtDisplay =
        _foundAt != null ? DateFormat('yyyy년 M월 d일').format(_foundAt!) : '';

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
                      _buildSelectionItem(
                        value: foundAtDisplay,
                        hintText: '습득 일자를 선택하세요',
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DateSelect(
                                headerLine1: '찾으시는',
                                headerLine2: '날짜를 알려주세요',
                              ),
                            ),
                          );
                          if (result != null && result is DateTime) {
                            setState(() {
                              _foundAt = result;
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
                              builder: (_) => CategorySelect(
                                headerLine1: '찾으시는 물건의',
                                headerLine2: '종류를 알려주세요',
                              ),
                            ),
                          );
                          if (result != null) {
                            setState(() {
                              _selectedCategory =
                                  result['category'].toString();
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
                              builder: (_) => ColorSelect(
                                headerLine1: '찾으시는 물건의',
                                headerLine2: '색상을 알려주세요',
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
                  final apiStatus = _mapStatus(_selectedState);
                  final apiType = _mapStorage(_storageLocation);
                  String apiFoundAt = _foundAt != null
                      ? DateFormat('yyyy-MM-dd').format(_foundAt!)
                      : '';

                  Navigator.pop(context, {
                    'state': apiStatus,
                    'type': apiType,
                    'foundAt': apiFoundAt,
                    'category': _selectedCategory ?? '',
                    'color': _selectedColor?.toString() ?? '',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

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
