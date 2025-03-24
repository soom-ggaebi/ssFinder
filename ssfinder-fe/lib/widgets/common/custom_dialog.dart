import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAlertDialog extends StatelessWidget {
  final String? iconAsset;
  final Color? iconBackgroundColor;
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final Color? buttonColor; // 버튼 배경색 파라미터 추가
  final Color? buttonTextColor; // 버튼 텍스트 색상 파라미터 추가
  final Widget? buttonIcon; // 버튼 아이콘 파라미터 추가

  const CustomAlertDialog({
    Key? key,
    this.iconAsset = 'assets/images/chat/avatar_icon.svg', // 기본 아이콘 에셋
    this.iconBackgroundColor = const Color(0xFFFEE7AD), // 기본 배경색
    required this.message,
    required this.buttonText,
    required this.onButtonPressed,
    this.buttonColor = const Color(0xFF444444), // 기본 버튼 배경색
    this.buttonTextColor = Colors.white, // 기본 버튼 텍스트 색상
    this.buttonIcon, // 버튼 앞에 표시될 선택적 아이콘
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: 350,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(iconAsset!, width: 50, height: 50),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: buttonTextColor,
                minimumSize: const Size(double.infinity, 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child:
                  buttonIcon == null
                      ? Text(
                        buttonText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: buttonTextColor,
                        ),
                      )
                      : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buttonIcon!,
                          const SizedBox(width: 8),
                          Text(
                            buttonText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: buttonTextColor,
                            ),
                          ),
                        ],
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
