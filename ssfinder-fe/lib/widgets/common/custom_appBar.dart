import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBackPressed;
  final VoidCallback onClosePressed;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.onBackPressed,
    required this.onClosePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 56, // 명시적인 높이 설정
      centerTitle: true,
      titleSpacing: 0, // 타이틀 간격 조정
      // 하단 테두리 추가
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: const Color(0xFF4F4F4F), height: 1.0),
      ),

      // 뒤로 가기 버튼
      leading: Center(
        // Container 대신 Center 위젯 사용
        child: SizedBox(
          width: 35,
          height: 35,
          child: IconButton(
            icon: SvgPicture.asset(
              'assets/images/common/appBar/back_button.svg',
              width: 35,
              height: 35,
            ),
            onPressed: onBackPressed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(), // const 추가
          ),
        ),
      ),

      // 타이틀
      title: Container(
        alignment: Alignment.center, // 중앙 정렬 강화
        child: Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),

      // 닫기 버튼
      actions: [
        Center(
          // Container 대신 Center 위젯 사용
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              width: 35,
              height: 35,
              child: IconButton(
                icon: SvgPicture.asset(
                  'assets/images/common/appBar/close_button.svg',
                  width: 35,
                  height: 35,
                ),
                onPressed: onClosePressed,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(), // const 추가
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
