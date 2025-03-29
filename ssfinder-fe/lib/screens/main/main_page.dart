import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/services/kakao_login_service.dart';
import 'package:sumsumfinder/screens/main/noti_list_page.dart';
import 'package:sumsumfinder/screens/main/my_page.dart';
import 'package:sumsumfinder/widgets/main/login_widget.dart';
import 'package:sumsumfinder/widgets/main/weather_widget.dart';
import 'package:sumsumfinder/widgets/main/statistics_widget.dart';
import 'package:sumsumfinder/widgets/main/user_stats_widget.dart';
import 'package:sumsumfinder/widgets/main/action_buttons_widget.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // 카카오 로그인 서비스 인스턴스 (필요한 경우 MyPage 기능 호출에 사용)
  final KakaoLoginService _kakaoLoginService = KakaoLoginService();

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

              return Column(
                children: [
                  // 상단 아이콘 버튼들
                  _buildTopBar(context),

                  const Spacer(flex: 1),

                  // 로그인 컨테이너
                  const LoginWidget(),

                  const Spacer(flex: 1),

                  // 날씨 및 검색 컨테이너
                  const WeatherWidget(),

                  const Spacer(flex: 1),

                  // 분실물 카운트 컨테이너
                  const StatisticsWidget(),

                  const Spacer(flex: 1),

                  // 등록한 분실물 및 습득물 카운트 컨테이너
                  const UserStatsWidget(),

                  const Spacer(flex: 1),

                  // 물건 찾기/주웠어요 버튼
                  ActionButtonsWidget(availableHeight: availableHeight),

                  const Spacer(flex: 1),

                  // 하단 배너 (높이 제한)
                  _buildBottomBanner(),

                  // 하단에 약간의 여백 추가 (오버플로우 방지)
                  const SizedBox(height: 8),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/images/main/noti_icon.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            if (_kakaoLoginService.isLoggedIn.value) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationPage(),
                ),
              );
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('로그인이 필요한 기능입니다.')));
            }
          },
        ),
        IconButton(
          icon: SvgPicture.asset(
            'assets/images/main/myPage_icon.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () {
            if (_kakaoLoginService.isLoggedIn.value) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPage()),
              );
            } else {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('로그인이 필요한 기능입니다.')));
            }
          },
        ),
      ],
    );
  }

  Widget _buildBottomBanner() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0)),
      child: SvgPicture.asset(
        'assets/images/main/bottom_banner.svg',
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
      ),
    );
  }
}
