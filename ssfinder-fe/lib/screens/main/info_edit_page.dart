import 'package:flutter/material.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:sumsumfinder/widgets/common/random_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class InfoEditPage extends StatefulWidget {
  final KakaoLoginService kakaoLoginService;

  const InfoEditPage({Key? key, required this.kakaoLoginService})
    : super(key: key);

  @override
  State<InfoEditPage> createState() => _InfoEditPageState();
}

class _InfoEditPageState extends State<InfoEditPage> {
  late final KakaoLoginService _kakaoLoginService;
  bool isLoading = true;
  bool isSaving = false;

  // 텍스트 컨트롤러들
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  // final TextEditingController _birthController = TextEditingController();
  // final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();

  // 사용자 이름 (읽기 전용)
  late String _userName;

  @override
  void initState() {
    super.initState();
    debugPrint('InfoEditPage - initState 호출됨');
    try {
      _kakaoLoginService = widget.kakaoLoginService;
      debugPrint('KakaoLoginService 인스턴스 할당됨');
      _loadUserInfo();
      debugPrint('_loadUserInfo 메서드 호출됨');
    } catch (e) {
      debugPrint('initState 중 오류 발생: $e');
    }
  }

  @override
  void dispose() {
    // 컨트롤러 해제
    _userNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  // JWT 토큰 가져오기 메서드 대체
  Future<String?> _getJwtToken() async {
    debugPrint('KakaoLoginService에서 JWT 토큰 가져오기 시작...');
    try {
      // KakaoLoginService의 getAccessToken 메서드 사용
      final token = await _kakaoLoginService.getAccessToken();

      if (token != null) {
        debugPrint('JWT 토큰 로드 성공: ${token}');
        return token;
      } else {
        debugPrint('JWT 토큰이 없습니다. 로그인이 필요합니다.');
        return null;
      }
    } catch (e) {
      debugPrint('JWT 토큰 가져오기 중 오류: $e');
      return null;
    }
  }

  // 사용자 정보 로드
  Future<void> _loadUserInfo() async {
    setState(() {
      isLoading = true;
    });

    try {
      // 기본 사용자 정보 로드
      _userName =
          _kakaoLoginService.user?.kakaoAccount?.profile?.nickname ?? "사용자";
      _nicknameController.text =
          _kakaoLoginService.user?.kakaoAccount?.profile?.nickname ?? "";
      _emailController.text =
          _kakaoLoginService.user?.kakaoAccount?.email ?? "";

      // if (_kakaoLoginService.user?.kakaoAccount?.birthyear != null &&
      //     _kakaoLoginService.user?.kakaoAccount?.birthday != null) {
      //   _birthController.text =
      //       "${_kakaoLoginService.user?.kakaoAccount?.birthyear}-${_kakaoLoginService.user?.kakaoAccount?.birthday?.substring(0, 2)}-${_kakaoLoginService.user?.kakaoAccount?.birthday?.substring(2, 4)}";
      // } else {
      //   _birthController.text = "";
      // }

      // 전화번호 정보
      // _phoneController.text =
      //     _kakaoLoginService.user?.kakaoAccount?.phoneNumber ?? "";
      // print('카카오 사용자 정보 로드: $_userName, ${_emailController.text}');

      // 활동 지역 정보 로드 (백엔드에서 가져오거나 로컬 저장소에서 가져오기)
      final prefs = await SharedPreferences.getInstance();
      _areaController.text =
          prefs.getString('user_area') ?? "동네를 설정해주세요"; // 기본값 설정

      // JWT 토큰 가져오기
      final jwtToken = await _getJwtToken();

      if (jwtToken != null) {
        try {
          final response = await http.get(
            Uri.parse('${dotenv.env['BACKEND_URL']}/api/users'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $jwtToken',
            },
          );
          print('사용자 정보 응답 상태 코드: ${response.statusCode}');
          if (response.statusCode == 200 && response.body.isNotEmpty) {
            // 이 부분을 다음과 같이 수정:
            final responseBody = utf8.decode(response.bodyBytes);
            final responseData = json.decode(responseBody);
            print('사용자 정보 응답: $responseBody...');

            if (responseData['success'] == true &&
                responseData['data'] != null) {
              final userData = responseData['data'];
              print('사용자 정보 로드 성공: $userData');

              // 서버에서 추가 정보 있으면 업데이트
              if (userData['my_region'] != null) {
                _areaController.text = userData['my_region'];
                print('지역 정보 업데이트: ${userData['my_region']}');
              }
              if (userData['nickname'] != null) {
                _nicknameController.text = userData['nickname'];
                print('닉네임 업데이트: ${userData['nickname']}');
              }
              // if (userData['birth'] != null) {
              //   _birthController.text = userData['birth'];
              //   print('생일 업데이트: ${userData['birth']}');
              // }
              // if (userData['phone'] != null) {
              //   _phoneController.text = userData['phone'];
              //   print('휴대폰 번호 업데이트: ${userData['phone']}');
              // }
            } else {
              print('사용자 정보 로드 실패: ${responseData['error']}');
            }
          } else {
            print(
              '사용자 정보 로드 실패: 상태 코드 ${response.statusCode}, 응답: ${response.body}',
            );
          }
        } catch (e) {
          print('서버에서 사용자 정보 로드 중 예외 발생: $e');
        }
      } else {
        print('JWT 토큰이 없어 서버에서 사용자 정보를 가져올 수 없습니다.');
      }
    } catch (e) {
      print('사용자 정보 로드 중 오류: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
      print('사용자 정보 로드 완료');
    }
  }

  // 사용자 정보 저장 메서드에 로그 추가
  Future<void> _saveUserInfo() async {
    setState(() {
      isSaving = true;
    });
    print('사용자 정보 저장 시작');

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 로컬 저장소에 정보 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_area', _areaController.text);
      print('로컬 저장소에 지역 정보 저장: ${_areaController.text}');

      // JWT 토큰 가져오기
      final jwtToken = await _getJwtToken();

      if (jwtToken == null) {
        print('JWT 토큰이 없어 정보를 저장할 수 없습니다.');
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('로그인 상태를 확인해주세요.')),
        );
        return;
      }

      final requestBody = {
        'nickname': _nicknameController.text,
        'my_region': _areaController.text,
        // 'birth': _birthController.text,
        // 'phone': _phoneController.text,
      };
      print('정보 저장 요청 본문: $requestBody');

      final response = await http.put(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: json.encode(requestBody),
      );

      print('정보 저장 응답 상태 코드: ${response.statusCode}');
      final responseBody = utf8.decode(response.bodyBytes);
      print('정보 저장 응답 본문: $responseBody');

      if (response.statusCode == 200) {
        final responseData = json.decode(responseBody);
        if (responseData['success'] == true) {
          print('사용자 정보 저장 성공');
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('회원 정보가 성공적으로 수정되었습니다.')),
          );
          Navigator.of(context).pop();
        } else {
          print('사용자 정보 저장 실패: ${responseData['error']}');
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                '정보 저장 실패: ${responseData['error'] ?? "알 수 없는 오류"}',
              ),
            ),
          );
        }
      } else {
        print(
          '사용자 정보 저장 실패: 상태 코드 ${response.statusCode}, 응답: ${utf8.decode(response.bodyBytes)}',
        );
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('정보 저장 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('사용자 정보 저장 중 예외 발생: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('정보 저장 중 오류 발생: $e')),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
      print('사용자 정보 저장 처리 완료');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '회원 정보 수정',
        onBackPressed: () => Navigator.of(context).pop(),
        onClosePressed:
            () => Navigator.of(context).popUntil((route) => route.isFirst),
      ),
      body:
          isLoading
              ? Center(child: CircularProgressIndicator())
              : _buildEditForm(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: isSaving ? null : _saveUserInfo,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6750A4),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child:
              isSaving
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text('저장하기'),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 정보 섹션
            Text(
              '프로필 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // 프로필 아이콘
            Center(
              child: Column(
                children: [
                  RandomAvatarProfileIcon(
                    userId: _kakaoLoginService.user!.id.toString(),
                    size: 80.0,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_userName}님',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    '카카오 계정으로 연동됨',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 개인 정보 섹션
            Text(
              '개인 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // // 이름 입력 필드 (읽기 전용)
            // _buildTextField(
            //   label: '이름',
            //   controller: _userNameController,
            //   hint: '이름',
            //   enabled: false,
            // ),
            // const SizedBox(height: 16),

            // 닉네임 입력 필드 (수정 가능)
            _buildTextField(
              label: '닉네임',
              controller: _nicknameController,
              hint: '닉네임을 입력하세요',
            ),

            // const SizedBox(height: 16),

            // // 생년월일 입력 필드
            // _buildTextField(
            //   label: '생년월일',
            //   controller: _birthController,
            //   hint: 'YYYY-MM-DD',
            // ),

            // const SizedBox(height: 16),

            // // 휴대폰 번호 입력 필드
            // _buildTextField(
            //   label: '휴대폰 번호',
            //   controller: _phoneController,
            //   hint: '010-XXXX-XXXX',
            // ),
            const SizedBox(height: 16),

            // 이메일 입력 필드 (읽기 전용)
            _buildTextField(
              label: '이메일',
              controller: _emailController,
              hint: '이메일 주소',
              enabled: false,
            ),

            const SizedBox(height: 32),

            // 활동 정보 섹션
            Text(
              '활동 정보',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // 활동 지역 입력 필드
            _buildTextField(
              label: '활동 지역',
              controller: _areaController,
              hint: '주로 활동하는 지역을 입력하세요',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool enabled = true,
    String? helpText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF6750A4)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
          ),
        ),
        if (helpText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              helpText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
