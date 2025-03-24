import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;

  const AppText(
    this.text, {
    Key? key,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 기본 스타일을 애플리케이션의 labelMedium으로 설정
    final defaultStyle = Theme.of(context).textTheme.labelMedium;

    // 사용자가 지정한 스타일 속성으로 기본 스타일을 오버라이드
    return Text(
      text,
      style: (style ?? defaultStyle)?.copyWith(
        color: color ?? (style?.color ?? defaultStyle?.color),
        fontWeight:
            fontWeight ?? (style?.fontWeight ?? defaultStyle?.fontWeight),
        fontSize: fontSize ?? (style?.fontSize ?? defaultStyle?.fontSize),
        fontFamily: 'GmarketSans',
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
