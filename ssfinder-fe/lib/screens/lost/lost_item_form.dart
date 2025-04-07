import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/lost_items_api_service.dart';
import '../../widgets/selects/category_select.dart';
import '../../widgets/selects/color_select.dart';
import '../../widgets/selects/location_select.dart';
import '../../widgets/selects/date_select.dart';

class LostItemForm extends StatefulWidget {
  const LostItemForm({Key? key}) : super(key: key);

  @override
  _LostItemFormState createState() => _LostItemFormState();
}

class _LostItemFormState extends State<LostItemForm> {
  final LostItemsApiService _apiService = LostItemsApiService();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  int? _selectedCategoryId;
  String? _selectedColor;
  String? _selectedLocation;
  DateTime? _selectedDate;
  File? _selectedImage;

  // 위치 정보
  double? _latitude;
  double? _longitude;

  bool _isLoading = false;

  final TextEditingController _itemNameController = TextEditingController();
  TextEditingController _detailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('위치 권한이 거부되었습니다.')));
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      print('위치 정보를 가져오는데 실패했습니다: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('위치 정보를 가져오는데 실패했습니다.')));
    }
  }

  // 이미지 선택
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지를 선택하는데 실패했습니다.')));
    }
  }

  // 폼 유효성 검사
  bool _validateForm() {
    if (_itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('품목명을 입력해주세요.')));
      return false;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('카테고리를 선택해주세요.')));
      return false;
    }

    if (_selectedColor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('색상을 선택해주세요.')));
      return false;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('분실장소를 선택해주세요.')));
      return false;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('분실일자를 선택해주세요.')));
      return false;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 정보를 가져오는 중입니다. 잠시 후 다시 시도해주세요.')),
      );
      return false;
    }

    return true;
  }

  // 분실물 등록
  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 날짜 포맷 변환 (yyyy-MM-dd)
      final formattedDate =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";

      final result = await _apiService.postLostItem(
        itemCategoryId: _selectedCategoryId!,
        title: _itemNameController.text,
        color: _selectedColor!,
        lostAt: formattedDate,
        location: _selectedLocation!,
        image: _selectedImage,
        detail: _detailController.text,
        latitude: _latitude!,
        longitude: _longitude!,
      );

      print('result: ${result}');

      setState(() {
        _isLoading = false;
      });

      // 성공 처리
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('분실물이 성공적으로 등록되었습니다.')));

      // 이전 화면으로 돌아가기
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('분실물 등록 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('분실물 등록에 실패했습니다: $e')));
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '분실물 등록하기',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '어떤 물건을',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Text(
                  '잃어버리셨나요?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // 이미지 선택
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      image:
                          _selectedImage != null
                              ? DecorationImage(
                                image: FileImage(_selectedImage!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        _selectedImage == null
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '이미지 선택하기',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                            : null,
                  ),
                ),
                const SizedBox(height: 20),

                // 품목명 입력
                const Text('품목명'),
                const SizedBox(height: 8),
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
                const SizedBox(height: 20),

                // 카테고리 선택
                const Text('카테고리'),
                const SizedBox(height: 8),
                _buildSelectionItem(
                  value: _selectedCategory ?? '',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CategorySelect(
                              headerLine1: '잃어버리신 물건의',
                              headerLine2: '종류를 알려주세요!',
                            ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        // result는 Map<String, dynamic> 형태로 category와 id를 포함
                        _selectedCategory = result['category'];
                        _selectedCategoryId = result['id'];
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 색상 선택
                const Text('색상'),
                const SizedBox(height: 8),
                _buildSelectionItem(
                  value: _selectedColor ?? '',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ColorSelect(
                              headerLine1: '잃어버리신 물건의',
                              headerLine2: '색상을 알려주세요!',
                            ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedColor = result;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 분실 장소 선택
                const Text('분실장소'),
                const SizedBox(height: 8),
                _buildSelectionItem(
                  value: _selectedLocation ?? '',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LocationSelect()),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedLocation = result['location'];
                        _latitude = result['latitude'];
                        _longitude = result['longitude'];
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // 분실 일자 선택
                const Text('분실일자'),
                const SizedBox(height: 8),
                _buildSelectionItem(
                  value:
                      _selectedDate != null
                          ? "${_selectedDate!.year}년 ${_selectedDate!.month.toString().padLeft(2, '0')}월 ${_selectedDate!.day.toString().padLeft(2, '0')}일"
                          : '',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => DateSelect(
                              headerLine1: '물건을 잃어버리신',
                              headerLine2: '날짜를 알려주세요!',
                            ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedDate = result;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

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
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('작성 완료'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
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
