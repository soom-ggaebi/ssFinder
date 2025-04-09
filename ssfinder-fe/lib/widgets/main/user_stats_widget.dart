import 'package:flutter/material.dart';
import 'package:sumsumfinder/widgets/common/app_text.dart';
import 'package:sumsumfinder/screens/lost/lost_page.dart';
import 'package:sumsumfinder/widgets/main/found/found_page.dart';

class UserStatsWidget extends StatelessWidget {
  const UserStatsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LostPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F1FF),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: const [
                  AppText('내가 등록한 분실물'),
                  SizedBox(height: 2.0),
                  AppText(
                    '2건',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF406299),
                    ),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FoundPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 10.0,
                horizontal: 16.0,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F1FF),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: const [
                  AppText('내가 등록한 습득물'),
                  SizedBox(height: 2.0),
                  AppText(
                    '1건',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF406299),
                    ),
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
