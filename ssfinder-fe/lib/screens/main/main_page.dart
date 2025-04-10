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
  // 카카오 로그인 서비스 인스턴스 (필요한 경우 MyPage 기능 호출에 사용)
  final KakaoLoginService _kakaoLoginService = KakaoLoginService();

  @override
  Widget build(BuildContext context) {
    // 디바이스 크기 정보 가져오기
    final screenSize = MediaQuery.of(context).size;
    final screenHeight = screenSize.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(screenHeight * 0.02), // 상대적 패딩
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // 상단 아이콘 버튼들
                  _buildTopBar(context),

                  // 메인 콘텐츠를 Expanded로 감싸서 남은 공간을 균등하게 분배
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceEvenly, // 균등 배치를 위한 설정
                        children: [
                          // 로그인 컨테이너
                          const LoginWidget(),

                          // 날씨 및 검색 컨테이너
                          const WeatherWidget(),

                          // 하단 배너
                          _buildBottomBanner(screenHeight),

                          // 등록한 분실물 및 습득물 카운트 컨테이너
                          const UserStatsWidget(),

                          // 물건 찾기/주웠어요 버튼
                          ActionButtonsWidget(
                            availableHeight: constraints.maxHeight * 0.8,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양 끝에 요소 배치
      children: [
        // 좌측 끝에 로고 배치 - 화면 너비에 따라 조정
        Padding(
          padding: EdgeInsets.only(left: screenWidth * 0.02),
          child: SvgPicture.asset(
            'assets/images/main/logo.svg',
            width: screenWidth * 0.25, // 화면 너비의 25%
            height: screenWidth * 0.06, // 너비에 비례한 높이
          ),
        ),

        // 오른쪽 끝에 아이콘 배치
        Row(
          mainAxisSize: MainAxisSize.min, // 아이콘들이 차지하는 공간만 사용
          children: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/images/main/noti_icon.svg',
                width: screenWidth * 0.06, // 화면 너비에 비례
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
                width: screenWidth * 0.06, // 화면 너비에 비례
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
        height: screenHeight * 0.08, // 화면 높이의 8%
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0), // 테두리를 둥글게 설정
        ),
        child: ClipRRect(
          // 이미지도 둥근 모서리로 클리핑
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
