import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/screens/main/main_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final KakaoLoginService _kakaoLoginService = KakaoLoginService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (!_isInitialized) {
      _isInitialized = true;

      // 1. 자동 로그인 시도
      await _kakaoLoginService.autoLogin();

      // 2. 주기적 토큰 갱신 설정
      await _kakaoLoginService.setupPeriodicTokenRefresh();

      // 3. 메인 화면으로 이동 (자동 로그인 성공 여부와 관계없이)
      // 로그인 상태는 이미 KakaoLoginService.isLoggedIn에 저장됨
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고 이미지
            SvgPicture.asset('assets/images/logo.svg', width: 150, height: 150),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
