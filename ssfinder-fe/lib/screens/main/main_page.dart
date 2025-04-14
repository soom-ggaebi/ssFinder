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
import 'package:sumsumfinder/screens/main/nearby_storage_select.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final KakaoLoginService _kakaoLoginService = KakaoLoginService();
  final GlobalKey<UserStatsWidgetState> userStatsKey =
      GlobalKey<UserStatsWidgetState>();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenHeight * 0.02),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // 로그인 위젯
                          const LoginWidget(),
                          // 날씨 위젯
                          const WeatherWidget(),
                          // 하단 배너
                          _buildBottomBanner(screenHeight),
                          // UserStatsWidget에 GlobalKey를 할당
                          UserStatsWidget(key: userStatsKey),
                          // 액션 버튼 위젯 (여기서 등록 성공 시 refresh() 호출)
                          ActionButtonsWidget(
                            availableHeight: constraints.maxHeight * 0.8,
                            onRegistrationSuccess: () {
                              print("onRegistrationSuccess called");
                              userStatsKey.currentState?.refresh();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 좌측: 로고
        Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.02),
          child: SvgPicture.asset(
            'assets/images/main/logo.svg',
            width: screenWidth * 0.5,
            height: screenWidth * 0.08,
          ),
        ),
        // 우측: 아이콘 버튼들 (알림, 마이페이지)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/images/main/noti_icon.svg',
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인이 필요한 기능입니다.')),
                  );
                }
              },
            ),
            IconButton(
              icon: SvgPicture.asset(
                'assets/images/main/myPage_icon.svg',
                width: screenWidth * 0.06,
                height: screenWidth * 0.06,
              ),
              onPressed: () {
                if (_kakaoLoginService.isLoggedIn.value) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MyPage()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('로그인이 필요한 기능입니다.')),
                  );
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBanner(double screenHeight) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NearbyStorageSelect()),
        );
      },
      child: Container(
        width: double.infinity,
        height: screenHeight * 0.08,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.0)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: SvgPicture.asset(
            'assets/images/main/bottom_banner.svg',
            fit: BoxFit.fitWidth,
            alignment: Alignment.center,
          ),
        ),
      ),
    );
  }
}
