import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RandomAvatarProfileIcon extends StatelessWidget {
  final double size;
  final String userId; // 사용자 ID는 필수 파라미터로 변경

  const RandomAvatarProfileIcon({
    Key? key,
    required this.userId, // 필수로 변경
    this.size = 60.0,
  }) : super(key: key);

  // userId를 기반으로 일관된 색상 생성
  Color getDeterministicColor() {
    // 사용할 배경색 목록
    final List<Color> backgroundColors = [
      Color.fromARGB(255, 255, 240, 187), // 노란색
      Color.fromARGB(255, 255, 255, 255), // 흰색
      Color.fromARGB(255, 208, 231, 183), // 연두색
      Color(0xFF80DEEA), // 하늘색
      Color(0xFFCF93D9), // 보라색
      Color.fromARGB(255, 255, 191, 191), // 분홍색
    ];

    // userId의 해시코드를 사용해 일관된 인덱스 생성
    final int hash = userId.hashCode.abs();
    final int colorIndex = hash % backgroundColors.length;

    return backgroundColors[colorIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: getDeterministicColor(),
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
