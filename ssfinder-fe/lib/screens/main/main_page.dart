import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/screens/home_page.dart';
import 'package:sumsumfinder/widgets/common/custom_dialog.dart';
import 'package:sumsumfinder/screens/main/notifications_page.dart';
import 'package:sumsumfinder/widgets/common/app_text.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // 카카오 로그인 서비스 인스턴스
  final KakaoLoginService _kakaoLoginService = KakaoLoginService();

  // 네비게이터 키 추가
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 로그인 상태 확인
    _checkLoginStatus();

    // 로그인 상태 변경 리스너 추가
    _kakaoLoginService.isLoggedIn.addListener(_loginStateChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    _kakaoLoginService.isLoggedIn.removeListener(_loginStateChanged);
    super.dispose();
  }

  // 로그인 상태 확인
  Future<void> _checkLoginStatus() async {
    await _kakaoLoginService.checkLoginStatus();
  }

  // 로그인 상태 변경 시 화면 갱신
  void _loginStateChanged() {
    setState(() {}); // UI 갱신
  }

  // 로그인 시도 함수
  Future<void> _attemptLogin() async {
    try {
      // 통합 로그인 프로세스 사용
      bool loginSuccess = await _kakaoLoginService.loginWithBackendAuth();
      if (loginSuccess) {
        setState(() {}); // UI 갱신
      } else {
        print('로그인 또는 백엔드 인증 실패');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (e) {
      print('로그인 중 오류 발생: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그인 중 오류가 발생했습니다: $e')));
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 사용 가능한 총 높이
              final availableHeight = constraints.maxHeight;
              // 화면 비율에 따른 크기 계산 헬퍼 함수
              double getHeightPercent(double percent) =>
                  availableHeight * percent;
              // 기본 여백 크기 (화면 높이의 2%)
              final spacingHeight = availableHeight * 0.02;

              return Column(
                children: [
                  // 상단 아이콘 버튼들
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/images/main/noti_icon.svg',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationPage(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: SvgPicture.asset(
                          'assets/images/main/myPage_icon.svg',
                          width: 24,
                          height: 24,
                        ),
                        onPressed: () {
                          // 로그인 상태일 때만 회원탈퇴 다이얼로그 표시
                          if (_kakaoLoginService.isLoggedIn.value) {
                            _processAccountDeletion(context);
                          } else {
                            // 로그인되지 않은 상태면 로그인 필요 메시지 표시
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('회원탈퇴를 위해 먼저 로그인해주세요.'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // 로그인 컨테이너
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12.0,
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1FF),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (!_kakaoLoginService.isLoggedIn.value) {
                          print('클릭 감지됨');
                          try {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                print('다이얼로그 빌더 시작');
                                return CustomAlertDialog(
                                  message: '로그인하고 다양한 기능을 사용해보세요!',
                                  buttonText: '카카오 로그인',
                                  buttonColor: const Color(0xFFFFE100),
                                  buttonTextColor: const Color(0xFF3C1E1E),
                                  buttonIcon: SvgPicture.asset(
                                    'assets/images/main/kakao_logo.svg',
                                    width: 20,
                                    height: 20,
                                  ),
                                  onButtonPressed: () {
                                    Navigator.of(context).pop();
                                    _attemptLogin(); // 카카오 로그인 시도
                                  },
                                );
                              },
                            );
                            print('showDialog 호출 완료');
                          } catch (e) {
                            print('오류 발생: $e');
                          }
                        } else {
                          // 이미 로그인한 상태면 로그아웃 확인 다이얼로그 표시
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
                                    },
                                    child: const Text('로그아웃'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: Row(
                        children: [
                          AppText(
                            _kakaoLoginService.isLoggedIn.value
                                ? '${_kakaoLoginService.user?.kakaoAccount?.profile?.nickname ?? "사용자"}님 안녕하세요'
                                : '로그인하러 가기',
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 1),

                  // 날씨 및 검색 컨테이너
                  Container(
                    width: double.infinity,
                    height: 120, // 높이 더 줄임
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Stack(
                      children: [
                        // 배경 이미지
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.asset(
                            'assets/images/main/weather_rain.png',
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // 오버레이
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              color: Colors.black.withOpacity(0.4),
                            ),
                          ),
                        ),
                        // 내용 컨테이너
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0), // 패딩 줄임
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Text(
                                      '오늘의 날씨는? ',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Text(
                                      '💧비💧',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4.0), // 간격 더 축소
                                const Text(
                                  '우산 챙기는 거 잊지 마세요!',
                                  style: TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 8.0), // 간격 더 축소
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0,
                                    vertical: 6.0, // 패딩 줄임
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFD1D1D1).withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: const [
                                      Icon(
                                        Icons.search,
                                        color: Colors.white,
                                        size: 18,
                                      ), // 아이콘 크기 줄임
                                      SizedBox(width: 6.0), // 간격 줄임
                                      Text(
                                        '내 주변 분실물을 검색해보세요!',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                        ), // 폰트 크기 줄임
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // 분실물 카운트 컨테이너
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0, // 패딩 더 축소
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F1FF),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        AppText('장덕동에서 발견된 분실물 개수'),
                        AppText(
                          '15개',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 1),

                  // 등록한 분실물 및 습득물 카운트 컨테이너
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0, // 패딩 더 축소
                            horizontal: 16.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F1FF),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            children: const [
                              AppText('내가 등록한 분실물'),
                              SizedBox(height: 2.0), // 간격 더 축소
                              AppText(
                                '2건',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10.0, // 패딩 더 축소
                            horizontal: 16.0,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE9F1FF),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            children: const [
                              AppText('내가 등록한 습득물'),
                              SizedBox(height: 2.0), // 간격 더 축소
                              AppText(
                                '1건',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // 물건 찾기/주웠어요 버튼
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const HomePage(
                                      initialIndex: 1,
                                    ), // LostPage 인덱스
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: getHeightPercent(0.035),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              children: [
                                const AppText(
                                  '물건을',
                                  style: TextStyle(fontSize: 13.0),
                                ),
                                const AppText(
                                  '찾아줘요',
                                  style: TextStyle(fontSize: 13.0),
                                ),
                                SizedBox(height: getHeightPercent(0.015)),
                                SvgPicture.asset(
                                  'assets/images/main/lost_icon.svg',
                                  width: getHeightPercent(0.04),
                                  height: getHeightPercent(0.04),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => const HomePage(
                                      initialIndex: 2,
                                    ), // FoundPage 인덱스
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              vertical: getHeightPercent(0.035),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9F1FF),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              children: [
                                const AppText(
                                  '물건을',
                                  style: TextStyle(fontSize: 13.0),
                                ),
                                const AppText(
                                  '주웠어요',
                                  style: TextStyle(fontSize: 13.0),
                                ),
                                SizedBox(height: getHeightPercent(0.015)),
                                SvgPicture.asset(
                                  'assets/images/main/found_icon.svg',
                                  width: getHeightPercent(0.04),
                                  height: getHeightPercent(0.04),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 1),

                  // 하단 배너 (높이 제한)
                  Container(
                    width: double.infinity,
                    height: 60, // 높이 제한 추가
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: SvgPicture.asset(
                      'assets/images/main/bottom_banner.svg',
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.center,
                    ),
                  ),

                  // 하단에 약간의 여백 추가 (오버플로우 방지)
                  SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
