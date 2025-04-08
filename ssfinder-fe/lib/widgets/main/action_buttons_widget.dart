import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/screens/home_page.dart';
import 'package:sumsumfinder/widgets/common/app_text.dart';

class ActionButtonsWidget extends StatelessWidget {
  final double availableHeight;

  const ActionButtonsWidget({Key? key, required this.availableHeight})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 화면 비율에 따른 크기 계산 헬퍼 함수
    double getHeightPercent(double percent) => availableHeight * percent;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          const HomePage(initialIndex: 1), // LostPage 인덱스
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: getHeightPercent(0.035)),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  const AppText('찾아줘요'),
                  SizedBox(height: getHeightPercent(0.015)),
                  SvgPicture.asset(
                    'assets/images/main/lost_icon.svg',
                    width: getHeightPercent(0.8),
                    height: getHeightPercent(0.08),
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
                      (context) =>
                          const HomePage(initialIndex: 2), // FoundPage 인덱스
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: getHeightPercent(0.035)),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F1FF),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: [
                  const AppText('주웠어요'),
                  SizedBox(height: getHeightPercent(0.015)),
                  SvgPicture.asset(
                    'assets/images/main/found_icon.svg',
                    width: getHeightPercent(0.8),
                    height: getHeightPercent(0.08),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
