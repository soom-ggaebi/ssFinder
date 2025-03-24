import 'package:flutter/material.dart';

class OptionItem extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final Color? textColor;

  const OptionItem({
    Key? key,
    required this.text,
    required this.onTap,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double width;
  final double height;
  final double borderRadius;
  final bool hasShadow;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF619BF7),
    this.textColor = Colors.white,
    this.width = double.infinity,
    this.height = 50,
    this.borderRadius = 10,
    this.hasShadow = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow:
            hasShadow
                ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(child: Text(text, style: TextStyle(color: textColor))),
        ),
      ),
    );
  }
}

class TextIconButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final double width;
  final double height;
  final double borderRadius;
  final double iconSize;
  final double spacing;

  const TextIconButton({
    Key? key,
    required this.text,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF619BF7),
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.width = double.infinity,
    this.height = 50,
    this.borderRadius = 10,
    this.iconSize = 20,
    this.spacing = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: iconSize),
                SizedBox(width: spacing),
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final double iconSize;

  const CircleIconButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = const Color(0xFF619BF7),
    this.iconColor = Colors.white,
    this.size = 40,
    this.iconSize = 20,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, color: iconColor, size: iconSize)),
      ),
    );
  }
}
