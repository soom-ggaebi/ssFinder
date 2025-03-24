import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/screens/lost_page/lost_page.dart';
import 'package:sumsumfinder/screens/found_page/found_page.dart';
import 'package:sumsumfinder/screens/home_page.dart';
import 'package:sumsumfinder/widgets/common/custom_dialog.dart';
import 'package:sumsumfinder/screens/main/notifications_page.dart';
import 'package:sumsumfinder/widgets/common/app_text.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

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
                        onPressed: () {},
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
                                },
                              );
                            },
                          );
                          print('showDialog 호출 완료');
                        } catch (e) {
                          print('오류 발생: $e');
                        }
                      },
                      child: Row(
                        children: [AppText('로그인하러 가기', color: Colors.blue)],
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
