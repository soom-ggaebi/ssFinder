import 'dart:io';
import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gif_view/gif_view.dart';

import '../../models/found_items_model.dart';
import '../../services/ai_api_service.dart';
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
  final AiApiService _aiApiService = AiApiService();
  final FoundItemsApiService _apiService = FoundItemsApiService();
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory; // 카테고리
  String? _selectedCategoryId; // 선택된 카테고리 ID
  String? _selectedColor; // 색상
  String? _selectedLocation; // 습득 장소
  DateTime? _selectedDate; // 습득 일자
  File? _selectedImage; // 선택된 이미지 파일
  String? _imageUrl; // 이미지 URL

  // 위치 정보
  double? _latitude;
  double? _longitude;

  bool _isLoading = false;
  bool _isAiAnalyzing = false;

  // 텍스트 필드 컨트롤러
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    if (widget.itemToEdit != null) {
      _initFormWithExistingData();
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _detailController.dispose();
    super.dispose();
  }

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

      final Position position = await Geolocator.getCurrentPosition(
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _extractExifData(_selectedImage!);
        await _analyzeImage();
      }
    } catch (e) {
      print('이미지 선택 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지를 선택하는데 실패했습니다.')));
    }
  }

  Future<void> _extractExifData(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final Map<String, IfdTag> exifData = await readExifFromBytes(bytes);

      String? dateTimeString;
      if (exifData.containsKey('EXIF DateTimeOriginal')) {
        dateTimeString = exifData['EXIF DateTimeOriginal']?.printable;
      } else if (exifData.containsKey('Image DateTime')) {
        dateTimeString = exifData['Image DateTime']?.printable;
      }

      if (dateTimeString != null) {
        String formattedDateTime = dateTimeString.replaceFirstMapped(
          RegExp(r'^(\d{4}):(\d{2}):(\d{2})'),
          (match) => '${match[1]}-${match[2]}-${match[3]}',
        );
        DateTime? photoDate = DateTime.tryParse(formattedDateTime);
        if (photoDate != null) {
          setState(() {
            _selectedDate = photoDate;
          });
          print('Exif 촬영일자: $photoDate');
        }
      }

      // GPS 정보 추출
      if (exifData.containsKey('GPS GPSLatitude') &&
          exifData.containsKey('GPS GPSLongitude')) {
        List<dynamic> latValues = exifData['GPS GPSLatitude']!.values.toList();
        List<dynamic> lonValues = exifData['GPS GPSLongitude']!.values.toList();
        double latitude = _convertToDegree(latValues);
        double longitude = _convertToDegree(lonValues);
        setState(() {
          _latitude = latitude;
          _longitude = longitude;
        });
        print('Exif GPS 좌표 - 위도: $latitude, 경도: $longitude');
      }
    } catch (e) {
      print('Exif 데이터 추출 중 오류 발생: $e');
    }
  }

  double _convertToDegree(List values) {
    double d = _toDouble(values[0]);
    double m = _toDouble(values[1]);
    double s = _toDouble(values[2]);
    return d + (m / 60) + (s / 3600);
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _analyzeImage() async {
    if (_selectedImage == null) return;
    try {
      setState(() {
        _isLoading = true;
        _isAiAnalyzing = true;
      });
      final result = await _aiApiService.analyzeImage(image: _selectedImage!);
      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          // 타이틀 채우기
          if (_itemNameController.text.isEmpty) {
            _itemNameController.text = data['title'] ?? '';
          }
          // 색상 처리
          if (_selectedColor == null || _selectedColor!.isEmpty) {
            final Map<String, String> colorMapping = {
              '빨간.': '빨간색',
              '파랑색': '파란색',
              '노란 색': '노란색',
              '하얀색': '흰색',
              '보라색': '보라색',
              '갈색': '갈색',
              '블랙이에요.': '검정색',
              '회색': '회색',
              '베이지색': '베이지',
              '주황색': '주황색',
              '초록의': '초록색',
              '하늘색': '하늘색',
              '네이비': '남색',
              '분홍색': '분홍색',
            };
            _selectedColor =
                colorMapping.containsKey(data['color'])
                    ? colorMapping[data['color']]
                    : '기타';
          }
          // 상세 설명 채우기
          if (_detailController.text.isEmpty) {
            _detailController.text = data['description'] ?? '';
          }
          // 카테고리 채우기
          if (_selectedCategory == null || _selectedCategory!.isEmpty) {
            _selectedCategory = data['category'] ?? '';
            _selectedCategoryId = '';
          }
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지 분석 결과가 반영되었습니다.')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('이미지 분석에 실패했습니다.')));
      }
    } catch (e) {
      print('이미지 분석 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미지 분석 중 오류가 발생했습니다.')));
    } finally {
      setState(() {
        _isLoading = false;
        _isAiAnalyzing = false;
      });
    }
  }

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
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('습득일자를 선택해주세요.')));
      return false;
    }
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('습득장소를 선택해주세요.')));
      return false;
    }
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 정보를 가져오는 중입니다. 잠시 후 다시 시도해주세요.')),
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
        orElse: () => CategoryModel(id: 19, name: 'Default Category'),
      );
      final categoryId = matchingCategory.id;

      if (widget.itemToEdit != null) {
        // 수정
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('습득물이 성공적으로 등록되었습니다.')));
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('습득물 등록 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('습득물 등록에 실패했습니다.')));
    }
  }

  // 수정 모드
  void _initFormWithExistingData() {
    final item = widget.itemToEdit;

    _itemNameController.text = item.name;
    _detailController.text = item.detail;
    if (item.image != null) {
      _imageUrl = item.image;
    }

    setState(() {
      _selectedCategory =
          (item.minorCategory != null && item.minorCategory.isNotEmpty)
              ? "${item.majorCategory} > ${item.minorCategory}"
              : "${item.majorCategory}";
      _selectedCategoryId =
          (item.minorCategory != null && item.minorCategory.isNotEmpty)
              ? item.minorCategory
              : '';
      _selectedColor = item.color;
      _selectedLocation = item.location;
      if (item.foundAt != null) {
        _selectedDate = DateTime.parse(item.foundAt);
      }
      _latitude = item.latitude;
      _longitude = item.longitude;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '습득물 등록하기',
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
                _buildHeaderText(),
                const SizedBox(height: 20),
                _buildImageSelector(),
                const SizedBox(height: 20),
                _buildTextField('품목명', _itemNameController),
                const SizedBox(height: 20),
                _buildSelectionItem(
                  label: '카테고리',
                  value: _selectedCategory ?? '',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const CategorySelect(
                              headerLine1: '주우신 물건의',
                              headerLine2: '종류를 알려주세요!',
                            ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedCategory = result['category'];
                        _selectedCategoryId = result['categoryId'];
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                _buildSelectionItem(
                  label: '색상',
                  value: _selectedColor ?? '',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const ColorSelect(
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
                const SizedBox(height: 20),
                _buildSelectionItem(
                  label: '습득일자',
                  value:
                      _selectedDate != null
                          ? "${_selectedDate!.year}년 ${_selectedDate!.month.toString().padLeft(2, '0')}월 ${_selectedDate!.day.toString().padLeft(2, '0')}일"
                          : '',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const DateSelect(
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
                const SizedBox(height: 20),
                _buildSelectionItem(
                  label: '습득장소',
                  value: _selectedLocation ?? '',
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => LocationSelect(
                              date:
                                  _selectedDate != null
                                      ? "${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}"
                                      : null,
                            ),
                      ),
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
                _buildTextField('상세설명', _detailController, maxLines: 5),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading ? Colors.grey : Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _submitForm,
                  child: const Text('작성 완료'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading || _isAiAnalyzing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading && !_isAiAnalyzing)
                      const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    else if (_isAiAnalyzing)
                      Column(
                        children: [
                          Container(
                            width: 150,
                            height: 150,
                            child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: GifView.asset(
                              'assets/images/ai_analyzing.gif',
                              height: 150,
                              width: 150,
                              frameRate: 1, // 프레임 속도 설정
                              fit: BoxFit.cover,
                            ),
                          ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'AI가 이미지를 분석 중입니다',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '잠시만 기다려주세요...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderText() {
    return Column(
      children: const [
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
      ],
    );
  }

  Widget _buildImageSelector() {
    return GestureDetector(
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
                      Icon(Icons.image, size: 50, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('이미지 선택하기', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
                : null,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
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
      ],
    );
  }

  Widget _buildSelectionItem({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        Container(
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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
