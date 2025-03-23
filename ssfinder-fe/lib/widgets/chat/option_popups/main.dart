import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/widgets/common/custom_button.dart';
import './report.dart';

class MainOptionsPopup extends StatelessWidget {
  const MainOptionsPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OptionItem(
            text: '차단하기',
            onTap: () {
              Navigator.pop(context);
              // 차단하기 관련 로직 추가
            },
          ),
          OptionItem(
            text: '신고하기',
            onTap: () {
              Navigator.pop(context);
              _showReportOptionsPopup(context);
            },
          ),
          OptionItem(
            text: '알림 끄기',
            onTap: () {
              Navigator.pop(context);
              // 알림 끄기 관련 로직 추가
            },
          ),
          OptionItem(
            text: '채팅방 나가기',
            textColor: const Color(0xFFFF5252),
            onTap: () {
              Navigator.pop(context);
              // 채팅방 나가기 관련 로직 추가
            },
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: const BoxDecoration(color: Color(0xFFF8F8F8)),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Text(
                '창닫기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportOptionsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) => const ReportOptionsPopup(),
    );
  }
}
