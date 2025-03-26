import 'package:flutter/material.dart';
import 'package:sumsumfinder/widgets/common/app_text.dart';

class StatisticsWidget extends StatelessWidget {
  const StatisticsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
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
              color: Color(0xFF406299),
            ),
          ),
        ],
      ),
    );
  }
}
