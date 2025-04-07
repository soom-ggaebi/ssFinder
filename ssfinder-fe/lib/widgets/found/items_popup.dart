import 'package:flutter/material.dart';
import 'package:sumsumfinder/widgets/common/custom_button.dart';

class MainOptionsPopup extends StatelessWidget {
  const MainOptionsPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OptionItem(
            text: '수정하기',
            onTap: () {
              Navigator.pop(context);
              // 수정하기 관련 로직 추가
            },
          ),
          OptionItem(
            text: '삭제하기',
            onTap: () {
              Navigator.pop(context);
              // 삭제하기 관련 로직 추가
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
}
