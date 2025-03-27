import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/screens/home_page.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/widgets/common/app_text.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'package:sumsumfinder/widgets/common/random_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  // 카카오 로그인 서비스 인스턴스
  final KakaoLoginService _kakaoLoginService = KakaoLoginService();

  // 알림 설정 상태를 저장하는 변수
  bool _notificationEnabled = true;

  @override
  void initState() {
    super.initState();
    // 로그인 상태 확인 및 비로그인 시 자동 뒤로가기
    _checkLoginStatus();
    // dotenv 초기화 확인
    _ensureDotEnvLoaded().then((_) {
      // 알림 설정 상태 로드
      _loadNotificationSettings();
    });
  }

  // dotenv가 로드되었는지 확인하고, 로드되지 않았다면 로드
  Future<void> _ensureDotEnvLoaded() async {
    try {
      // dotenv가 이미 로드되었는지 확인 (BACKEND_URL 환경변수 존재 여부로 판단)
      if (dotenv.env['BACKEND_URL'] == null) {
        await dotenv.load();
      }
    } catch (e) {
      print('환경변수 로드 중 오류 발생: $e');
    }
  }

  // 로그인 상태 확인
  Future<void> _checkLoginStatus() async {
    await _kakaoLoginService.checkLoginStatus();

    // 로그인되지 않은 경우 자동으로 이전 페이지로 돌아가기
    if (!_kakaoLoginService.isLoggedIn.value && mounted) {
      // 약간의 딜레이를 두고 뒤로가기 (화면 전환 효과를 위해)
      Future.delayed(Duration.zero, () {
        Navigator.of(context).pop();
      });
    } else if (mounted) {
      setState(() {});
    }
  }

  // 알림 설정 상태 로드
  Future<void> _loadNotificationSettings() async {
    try {
      // 로컬 설정 먼저 로드 (빠른 UI 업데이트를 위해)
      final prefs = await SharedPreferences.getInstance();
      bool localSetting = prefs.getBool('notification_enabled') ?? true;

      setState(() {
        _notificationEnabled = localSetting;
      });

      // 서버에서 현재 설정 가져오기
      final response = await http.get(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/notifications/settings'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = json.decode(response.body);
        if (data.containsKey('enabled')) {
          setState(() {
            _notificationEnabled = data['enabled'];
          });
          // 서버 값으로 로컬 설정 업데이트
          await prefs.setBool('notification_enabled', _notificationEnabled);
        }
      }
    } catch (e) {
      print('알림 설정 로드 중 오류 발생: $e');
    }
  }

  // 알림 설정 상태 저장
  Future<void> _saveNotificationSettings(bool value) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    // 먼저 UI 업데이트 (사용자 경험을 위해)
    setState(() {
      _notificationEnabled = value;
    });

    try {
      // 서버에 설정 저장
      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND_URL']}/api/notifications/settings'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'notification_type': 'CHAT', // 전체 알림 설정
          'enabled': value,
        }),
      );

      if (response.statusCode == 204) {
        // 서버 저장 성공 시 로컬에도 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('notification_enabled', value);
      } else {
        // 서버 저장 실패 시 UI 롤백 및 오류 메시지
        setState(() {
          _notificationEnabled = !value;
        });
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('알림 설정 변경에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
    } catch (e) {
      // 예외 발생 시 UI 롤백 및 오류 메시지
      setState(() {
        _notificationEnabled = !value;
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('알림 설정 중 오류 발생: $e')),
      );
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
      body: _buildLoggedInView(),
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
                  RandomAvatarProfileIcon(
                    userId: _kakaoLoginService.user!.id.toString(),
                    size: 64.0,
                  ),
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

            // 알림 설정 추가
            _buildNotificationSetting(),
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

  // 알림 설정 위젯
  Widget _buildNotificationSetting() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications, color: Colors.grey[700], size: 20),
          const SizedBox(width: 12),
          Text('알림 설정', style: TextStyle(color: Colors.grey[800])),
          const Spacer(),
          // 로딩 상태를 관리하는 StatefulBuilder 사용
          StatefulBuilder(
            builder: (context, setInnerState) {
              return Switch(
                value: _notificationEnabled,
                onChanged: (value) async {
                  // 스위치 상태 변경 시 로딩 표시
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(
                      content: Text('알림 설정 변경 중...'),
                      duration: Duration(seconds: 1),
                    ),
                  );

                  await _saveNotificationSettings(value);
                },
                activeColor: Colors.white,
                activeTrackColor: const Color(0xFF6750A4),
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: Colors.grey[300],
              );
            },
          ),
        ],
      ),
    );
  }

  // 닉네임 가져오기
  String get _getNickname {
    return _kakaoLoginService.user?.kakaoAccount?.profile?.nickname ??
        "닉네임 정보 없음";
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
