import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/widgets/common/app_text.dart';
import 'package:sumsumfinder/widgets/common/custom_dialog.dart';
import 'package:sumsumfinder/screens/home_page.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({Key? key}) : super(key: key);

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  // 카카오 로그인 서비스 인스턴스
  final KakaoLoginService _kakaoLoginService = KakaoLoginService();
  bool _isLoading = true; // 초기 로딩 상태 추가

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 자동 로그인 시도
    _initializeAuth();

    // 로그인 상태 변경 리스너 추가
    _kakaoLoginService.isLoggedIn.addListener(_loginStateChanged);
  }

  @override
  void dispose() {
    // 리스너 제거
    _kakaoLoginService.isLoggedIn.removeListener(_loginStateChanged);
    super.dispose();
  }

  // 자동 로그인 및 인증 초기화
  Future<void> _initializeAuth() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 1. 기존 토큰 유효성 검사
      await _kakaoLoginService.checkLoginStatus();

      // 2. 토큰이 있고 유효하지만 백엔드 인증이 필요한 경우
      if (_kakaoLoginService.isLoggedIn.value) {
        // 액세스 토큰 가져오기
        final token = await _kakaoLoginService.getAccessToken();

        // 토큰이 있으면 백엔드에 유효성 확인 및 갱신
        if (token != null) {
          await _ensureBackendAuthentication();
        }
      }
    } catch (e) {
      print('인증 초기화 중 오류: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 백엔드 인증 확인 및 필요시 재인증
  Future<void> _ensureBackendAuthentication() async {
    try {
      // 1. 현재 저장된 토큰으로 사용자 정보 조회 시도
      final userProfile = await _kakaoLoginService.getUserProfile();

      // 2. 실패하면 토큰 갱신 시도
      if (userProfile == null) {
        final refreshed = await _kakaoLoginService.refreshAccessToken();

        // 3. 갱신도 실패하면 카카오 토큰으로 재인증 시도
        if (!refreshed) {
          if (_kakaoLoginService.user != null) {
            await _kakaoLoginService.authenticateWithBackend();
          }
        }
      }
    } catch (e) {
      print('백엔드 인증 확인 중 오류: $e');
    }
  }

  // 로그인 상태 변경 시 화면 갱신
  void _loginStateChanged() {
    if (mounted) {
      setState(() {}); // UI 갱신
    }
  }

  // 로그인 시도 함수
  Future<void> _attemptLogin() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 통합 로그인 프로세스 사용
      bool loginSuccess = await _kakaoLoginService.loginWithBackendAuth();

      if (loginSuccess) {
        // 로그인 성공 - 상태는 이미 KakaoLoginService에서 업데이트됨
      } else {
        print('로그인 또는 백엔드 인증 실패');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그인에 실패했습니다. 다시 시도해주세요.')),
          );
        }
      }
    } catch (e) {
      print('로그인 중 오류 발생: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그인 중 오류가 발생했습니다: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE9F1FF),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child:
          _isLoading
              ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF406299),
                    ),
                  ),
                ),
              )
              : InkWell(
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
                    // 이미 로그인한 상태이면 로그아웃 또는 회원 탈퇴 옵션 제공
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('계정 옵션'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.logout),
                                title: const Text('로그아웃'),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _kakaoLoginService.fullLogout(); // 통합 로그아웃 사용
                                },
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  '회원 탈퇴',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  _processAccountDeletion(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                },
                child: Row(
                  children: [
                    _kakaoLoginService.isLoggedIn.value
                        ? Row(
                          children: [
                            AppText(
                              '${_kakaoLoginService.user?.kakaoAccount?.profile?.nickname ?? "사용자"}',
                              color: Color(0xFF406299),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(width: 4), // 텍스트 사이 여백
                            const AppText(
                              '님 안녕하세요',
                              color: Color(0xFF406299),
                              fontSize: 15,
                            ),
                          ],
                        )
                        : const AppText(
                          '로그인하러 가기',
                          color: Color(0xFF406299),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                    const Spacer(),
                    _kakaoLoginService.isLoggedIn.value
                        ? const Icon(
                          Icons.person,
                          color: Color(0xFF406299),
                          size: 20,
                        )
                        : const Icon(
                          Icons.login,
                          color: Color(0xFF406299),
                          size: 20,
                        ),
                  ],
                ),
              ),
    );
  }
}
