// widgets/option_popups/report_options_popup.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/widgets/common/custom_button.dart';
import 'package:sumsumfinder/widgets/common/custom_dialog.dart';

class ReportOptionsPopup extends StatelessWidget {
  const ReportOptionsPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
            child: const Text(
              '사용자를 신고하거나 이유를 설명해주세요.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          OptionItem(
            text: '욕설, 비방, 혐오를 포함해요',
            onTap: () => _handleReportOption(context),
          ),
          OptionItem(
            text: '스팸 메시지를 보내요',
            onTap: () => _handleReportOption(context),
          ),
          OptionItem(text: '기타', onTap: () => _handleReportOption(context)),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: const BoxDecoration(color: Color(0xFFF8F8F8)),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: const Text(
                '취소',
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

  void _handleReportOption(BuildContext context) {
    Navigator.pop(context);
    _showReportCompletedDialog(context);
  }

  void _showReportCompletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          message: '신고가 정상적으로 접수되었습니다.',
          buttonText: '확인',
          onButtonPressed: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
