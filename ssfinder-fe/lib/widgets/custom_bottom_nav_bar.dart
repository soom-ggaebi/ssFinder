import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      elevation: 0,
      selectedFontSize: 12,
      selectedItemColor: Colors.blue,
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(
          icon: SvgPicture.asset('assets/images/common/navBar/main_icon.svg'),
          activeIcon: SvgPicture.asset(
            'assets/images/common/navBar/main_icon.svg',
          ),
          label: '메인',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset('assets/images/common/navBar/find_icon.svg'),
          activeIcon: SvgPicture.asset(
            'assets/images/common/navBar/find_icon.svg',
          ),
          label: '찾아줘요',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset('assets/images/common/navBar/found_icon.svg'),
          activeIcon: SvgPicture.asset(
            'assets/images/common/navBar/found_icon.svg',
          ),
          label: '주웠어요',
        ),
        BottomNavigationBarItem(
          icon: SvgPicture.asset('assets/images/common/navBar/chat_icon.svg'),
          activeIcon: SvgPicture.asset(
            'assets/images/common/navBar/chat_icon.svg',
          ),
          label: '채팅',
        ),
      ],
    );
  }
}
