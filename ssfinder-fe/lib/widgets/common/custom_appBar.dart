import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sumsumfinder/screens/home_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final VoidCallback? onClosePressed;
  final List<Widget>? customActions;
  final PreferredSizeWidget? bottom;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.onBackPressed,
    this.onClosePressed,
    this.customActions,
    this.bottom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 모든 요소에 동일한 크기와 패딩 적용
    const double iconSize = 40;
    const double sidePadding = 8;

    // 뒤로 가기 버튼 - 안전한 네비게이션 처리 추가
    final backButton = SizedBox(
      width: iconSize,
      height: iconSize,
      child: IconButton(
        icon: SvgPicture.asset(
          'assets/images/common/appBar/back_button.svg',
          width: iconSize,
          height: iconSize,
        ),
        onPressed: () {
          // 디버깅 정보 출력
          print('네비게이션 스택 정보: ${ModalRoute.of(context)?.settings.name}');
          print('네비게이션 pop 가능 여부: ${Navigator.canPop(context)}');

          // 사용자 정의 콜백이 있으면 사용
          if (onBackPressed != null) {
            onBackPressed!();
            return;
          }

          // 기본 안전한 뒤로가기 구현
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // 이전 페이지가 없는 경우 홈으로 이동
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomePage(initialIndex: 0),
              ),
            );
          }
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );

    // 기본 닫기 버튼 - 안전한 네비게이션 처리 추가
    final defaultCloseButton = SizedBox(
      width: iconSize,
      height: iconSize,
      child: IconButton(
        icon: SvgPicture.asset(
          'assets/images/common/appBar/close_button.svg',
          width: iconSize,
          height: iconSize,
        ),
        onPressed: () {
          // 사용자 정의 콜백이 있으면 사용
          if (onClosePressed != null) {
            onClosePressed!();
            return;
          }

          // 기본 안전한 홈으로 이동 구현
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const HomePage(initialIndex: 0),
            ),
            (route) => false, // 모든 이전 라우트 제거
          );
        },
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
      bottom:
          bottom ??
          PreferredSize(
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
  Size get preferredSize {
    // bottom이 있으면 그 높이를 더하고, 없으면 기본 테두리만큼만 추가
    return Size.fromHeight(56.0 + (bottom?.preferredSize.height ?? 1.0));
  }
}
