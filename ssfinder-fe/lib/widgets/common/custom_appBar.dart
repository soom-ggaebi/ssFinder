import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onBackPressed;
  final VoidCallback onClosePressed;
  final List<Widget>? customActions;

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.onBackPressed,
    required this.onClosePressed,
    this.customActions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 모든 요소에 동일한 크기와 패딩 적용
    const double iconSize = 40;
    const double sidePadding = 8;

    // 뒤로 가기 버튼
    final backButton = SizedBox(
      width: iconSize,
      height: iconSize,
      child: IconButton(
        icon: SvgPicture.asset(
          'assets/images/common/appBar/back_button.svg',
          width: iconSize,
          height: iconSize,
        ),
        onPressed: onBackPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );

    // 기본 닫기 버튼
    final defaultCloseButton = SizedBox(
      width: iconSize,
      height: iconSize,
      child: IconButton(
        icon: SvgPicture.asset(
          'assets/images/common/appBar/close_button.svg',
          width: iconSize,
          height: iconSize,
        ),
        onPressed: onClosePressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 56,
      automaticallyImplyLeading: false, // 자동 leading 비활성화
      centerTitle: true,
      titleSpacing: 0, // 타이틀 주변 기본 패딩 제거
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(color: const Color(0xFF4F4F4F), height: 1.0),
      ),

      // AppBar를 Row로 완전히 커스텀하여 요소들의 정확한 배치 제어
      title: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              // 왼쪽 패딩과 뒤로가기 버튼
              Padding(
                padding: const EdgeInsets.only(left: sidePadding),
                child: backButton,
              ),

              // 가운데 타이틀 - 남은 공간을 모두 차지하고 텍스트 중앙 정렬
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // 오른쪽 액션 버튼들
              Padding(
                padding: const EdgeInsets.only(right: sidePadding),
                child:
                    customActions != null
                        ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: customActions!,
                        )
                        : defaultCloseButton,
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(57); // 1px 테두리 포함
}
