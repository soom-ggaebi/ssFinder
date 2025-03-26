import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/screens/home_page.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/widgets/common/app_text.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:sumsumfinder/widgets/common/random_profile.dart';

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // 카카오 로그인 서비스 인스턴스
  final KakaoLoginService _kakaoLoginService = KakaoLoginService();

  @override
  void initState() {
    super.initState();
    // 로그인 상태 확인
    _checkLoginStatus();
  }

  // 로그인 상태 확인
  Future<void> _checkLoginStatus() async {
    await _kakaoLoginService.checkLoginStatus();
    if (mounted) {
      setState(() {});
    }
  }

  // 회원 탈퇴 처리 함수
  void _processAccountDeletion(BuildContext context) {
    // ScaffoldMessenger 미리 참조
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 확인 다이얼로그 표시
    showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('회원 탈퇴'),
          content: const Text('정말로 탈퇴하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                // 다이얼로그 닫기
                Navigator.of(dialogContext).pop(true);

                // 로딩 다이얼로그 표시 (로딩 다이얼로그 컨텍스트를 별도로 유지)
                BuildContext? loadingDialogContext;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext ctx) {
                    loadingDialogContext = ctx;
                    return const Center(child: CircularProgressIndicator());
                  },
                );

                // 회원 탈퇴 API 호출 (Future 처리)
                _kakaoLoginService
                    .deleteAccount()
                    .then((success) {
                      // 로딩 다이얼로그가 아직 표시 중인지 확인 후 닫기
                      if (loadingDialogContext != null) {
                        Navigator.of(loadingDialogContext!).pop();
                      }

                      if (success) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(content: Text('회원탈퇴가 완료되었습니다.')),
                        );

                        // 로그인 화면으로 이동
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder:
                                (context) => const HomePage(
                                  initialIndex: 0,
                                ), // 홈 페이지로 이동 (네브바 포함)
                          ),
                          (route) => false, // 모든 기존 화면을 제거
                        );
                      } else {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('회원탈퇴에 실패했습니다. 다시 시도해 주세요.'),
                          ),
                        );
                      }
                    })
                    .catchError((error) {
                      // 로딩 다이얼로그가 아직 표시 중인지 확인 후 닫기
                      if (loadingDialogContext != null) {
                        Navigator.of(loadingDialogContext!).pop();
                      }

                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Text('회원탈퇴 중 오류 발생: ${error.toString()}'),
                        ),
                      );
                    });
              },
              child: const Text('탈퇴하기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: '내 정보',
        onBackPressed: () {
          Navigator.pop(context);
        },
        onClosePressed: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
      body:
          _kakaoLoginService.isLoggedIn.value
              ? _buildLoggedInView()
              : _buildLoggedOutView(),
    );
  }

  Widget _buildLoggedInView() {
    final userName =
        _kakaoLoginService.user?.kakaoAccount?.profile?.nickname ?? "사용자";

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '프로필',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 12),

            // 사용자 정보 섹션
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F1FF),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 프로필 아이콘 추가
                  RandomAvatarProfileIcon(size: 64.0),
                  const SizedBox(width: 16),

                  // 사용자 정보
                  Expanded(
                    child: Column(
                      // Column으로 변경
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          // 이름과 닉네임을 담은 Row
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$userName님',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(width: 8), // 이름과 닉네임 사이 간격
                            Text(
                              '($_getNickname)',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID : ${_kakaoLoginService.user?.kakaoAccount?.email ?? '이메일 정보 없음'}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 활동 통계
            const Text(
              '활동',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  _buildStatItem('내가 등록한 분실물', '2건'),
                  const SizedBox(height: 12),
                  _buildStatItem('내가 등록한 습득물', '1건'),
                  const SizedBox(height: 12),
                  _buildStatItem('활동 지역', '장덕동'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 설정 섹션
            const Text(
              '설정',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildSettingsItem('로그아웃', Icons.logout, () {
              // 로그아웃 다이얼로그 표시
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('로그아웃 하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _kakaoLoginService.logout();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder:
                                  (context) => const HomePage(initialIndex: 0),
                            ),
                            (route) => false,
                          );
                        },
                        child: const Text('로그아웃'),
                      ),
                    ],
                  );
                },
              );
            }),
            const SizedBox(height: 8),
            _buildSettingsItem(
              '회원 탈퇴',
              Icons.person_remove,
              () => _processAccountDeletion(context),
              textColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  // 닉네임 가져오기
  String get _getNickname {
    return _kakaoLoginService.user?.kakaoAccount?.profile?.nickname ??
        "닉네임 정보 없음";
  }

  Widget _buildLoggedOutView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('로그인이 필요한 기능입니다', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // 메인 페이지로 돌아가기
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F51B5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[700])),
        AppText(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(
    String title,
    IconData icon,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? Colors.grey[700], size: 20),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: textColor ?? Colors.grey[800])),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }
}
