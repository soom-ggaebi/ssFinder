import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math';

class RandomAvatarProfileIcon extends StatelessWidget {
  final double size;

  const RandomAvatarProfileIcon({Key? key, this.size = 60.0}) : super(key: key);

  // 배경색 랜덤 선택 함수
  Color getRandomBackgroundColor() {
    // 사용할 배경색 목록
    final List<Color> backgroundColors = [
      Color.fromARGB(255, 255, 240, 187), // 노란색
      Color.fromARGB(255, 255, 255, 255), // 주황색
      Color.fromARGB(255, 208, 231, 183), // 연두색
      Color(0xFF80DEEA), // 하늘색
      Color(0xFFCF93D9), // 보라색
      Color.fromARGB(255, 255, 191, 191), // 분홍색
    ];

    final random = Random();
    return backgroundColors[random.nextInt(backgroundColors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: getRandomBackgroundColor(),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SvgPicture.asset(
          'assets/images/avatar_icon.svg',
          width: size * 0.7,
          height: size * 0.7,
        ),
      ),
    );
  }
}
