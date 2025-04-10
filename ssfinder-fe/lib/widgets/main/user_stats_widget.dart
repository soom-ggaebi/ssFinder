import 'package:flutter/material.dart';
import 'package:sumsumfinder/widgets/common/app_text.dart';
import 'package:sumsumfinder/screens/lost/lost_page.dart';
import 'package:sumsumfinder/widgets/main/found/found_page.dart';

class UserStatsWidget extends StatelessWidget {
  const UserStatsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 화면 높이에 따른 여백 계산
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalSpacing = screenHeight * 0.02; // 메인 페이지와 동일한 계산법 적용

    return Column(
      // Row 대신 Column 사용
      children: [
        // 첫 번째 컨테이너 (분실물)
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LostPage()),
            );
          },
          child: Container(
            width: double.infinity, // 전체 너비를 사용
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 16.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1FF),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 끝에 정렬
              children: const [
                AppText('내가 등록한 분실물'),
                SizedBox(height: 2.0),
                AppText(
                  '2건',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF406299),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 20.0), // 전체 여백과 동일한 간격 적용
        // 두 번째 컨테이너 (습득물)
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FoundPage()),
            );
          },
          child: Container(
            width: double.infinity, // 전체 너비를 사용
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 16.0,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F1FF),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 끝에 정렬
              children: const [
                AppText('내가 등록한 습득물'),
                SizedBox(height: 2.0),
                AppText(
                  '1건',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF406299),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
