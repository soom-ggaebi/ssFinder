import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/found_items_api_service.dart';
import '../../widgets/selects/category_select.dart';
import '../../widgets/selects/color_select.dart';
import '../../widgets/selects/location_select.dart';
import '../../widgets/selects/date_select.dart';

class FoundItemForm extends StatefulWidget {
  final dynamic itemToEdit;

  const FoundItemForm({Key? key, this.itemToEdit}) : super(key: key);

  @override
  _FoundItemFormState createState() => _FoundItemFormState();
}

class _FoundItemFormState extends State<FoundItemForm> {
  final FoundItemsApiService _apiService = FoundItemsApiService();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory; // 카테고리
  String? _selectedCategoryId; // 카테고리 ID
  String? _selectedColor; // 색상
  String? _selectedLocation; // 습득 장소
  DateTime? _selectedDate; // 습득 일자
  File? _selectedImage; // 선택된 이미지
  String? _imageUrl;

  // 위치 정보
  double? _latitude;
  double? _longitude;

  bool _isLoading = false;

  TextEditingController _itemNameController = TextEditingController(); // 품목명
  TextEditingController _detailController = TextEditingController(); // 상세 설명

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    if (widget.itemToEdit != null) {
      _initFormWithExistingData();
    }
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
          ).showSnackBar(SnackBar(content: Text('위치 권한이 거부되었습니다.')));
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
      ).showSnackBar(SnackBar(content: Text('위치 정보를 가져오는데 실패했습니다.')));
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
      ).showSnackBar(SnackBar(content: Text('이미지를 선택하는데 실패했습니다.')));
    }
  }

  // 폼 유효성 검사
  bool _validateForm() {
    if (_itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('품목명을 입력해주세요.')));
      return false;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('카테고리를 선택해주세요.')));
      return false;
    }

    if (_selectedColor == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('색상을 선택해주세요.')));
      return false;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('습득장소를 선택해주세요.')));
      return false;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('습득일자를 선택해주세요.')));
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

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final formattedDate =
          "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}";
      final categories = await _apiService.getCategories();
      final selectedCategoryName = _selectedCategory?.split(' > ').last.trim();
      final matchingCategory = categories.firstWhere(
        (category) => category.name == selectedCategoryName,
        orElse: () => throw Exception('선택한 카테고리를 찾을 수 없습니다.'),
      );

      final categoryId = matchingCategory.id;

      if (widget.itemToEdit != null) {
        // 수정
        print('수정');
        await _apiService.updateFoundItem(
          foundId: widget.itemToEdit.id,
          itemCategoryId: categoryId,
          name: _itemNameController.text,
          foundAt: formattedDate,
          location: _selectedLocation!,
          color: _selectedColor!,
          image: _selectedImage,
          detail: _detailController.text,
          latitude: _latitude!,
          longitude: _longitude!,
        );
      } else {
        // 생성
        await _apiService.postFoundItem(
          itemCategoryId: categoryId,
          name: _itemNameController.text,
          foundAt: formattedDate,
          location: _selectedLocation!,
          color: _selectedColor!,
          image: _selectedImage,
          detail: _detailController.text,
          latitude: _latitude!,
          longitude: _longitude!,
        );
      }

      setState(() {
        _isLoading = false;
      });

      // 성공 처리
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('습득물이 성공적으로 등록되었습니다.')));

      // 이전 화면으로 돌아가기
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('습득물 등록 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('습득물 등록에 실패했습니다.')));
    }
  }

  void _initFormWithExistingData() {
    final item = widget.itemToEdit;

    // 텍스트 필드 초기화
    _itemNameController.text = item.name;
    _detailController.text = item.detail;

    if (item.image != null) {
      _imageUrl = item.imageUrl;
    }

    // 선택 값 초기화
    setState(() {
      _selectedCategory = "${item.majorCategory} > ${item.minorCategory}";
      _selectedCategoryId = item.minorCategory;
      _selectedColor = item.color;
      _selectedLocation = item.location;

      // 날짜 변환 (문자열 -> DateTime)
      if (item.foundAt != null) {
        _selectedDate = DateTime.parse(item.foundAt);
      }

      // 위치 정보
      _latitude = item.latitude;
      _longitude = item.longitude;

      // 이미지는 URL에서 File로 변환이 필요하므로 별도 처리 필요
      // 실제 구현 시에는 이미지 URL을 저장하고 UI에서만 표시하는 방식으로 처리할 수 있음
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '습득물 등록하기',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '어떤 물건을',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                Text(
                  '주우셨나요?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),

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
                              : _imageUrl != null
                              ? DecorationImage(
                                image: NetworkImage(_imageUrl!),
                                fit: BoxFit.cover,
                              )
                              : null,
                    ),
                    child:
                        (_selectedImage == null && _imageUrl == null)
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
                SizedBox(height: 20),

                // 품목명 입력
                Text('품목명'),
                SizedBox(height: 8),
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
                SizedBox(height: 20),

                // 카테고리 선택
                Text('카테고리'),
                SizedBox(height: 8),
                _buildSelectionItem(
                  value: _selectedCategory ?? '',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => CategorySelect(
                              headerLine1: '주우신 물건의',
                              headerLine2: '종류를 알려주세요!',
                            ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        // result는 Map<String, dynamic> 형태로 category와 id를 포함
                        _selectedCategory = result['category'];
                        _selectedCategoryId = result['categoryId'];
                      });
                    }
                  },
                ),
                SizedBox(height: 20),

                // 색상 선택
                Text('색상'),
                SizedBox(height: 8),
                _buildSelectionItem(
                  value: _selectedColor ?? '',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ColorSelect(
                              headerLine1: '주우신 물건의',
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
                SizedBox(height: 20),

                // 습득 장소 선택
                Text('습득장소'),
                SizedBox(height: 8),
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
                SizedBox(height: 20),

                // 습득 일자 선택
                Text('습득일자'),
                SizedBox(height: 8),
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
                              headerLine1: '물건을 주우신',
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
                SizedBox(height: 20),

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
                    minimumSize: Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child:
                      _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text('작성 완료'),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(child: CircularProgressIndicator()),
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
