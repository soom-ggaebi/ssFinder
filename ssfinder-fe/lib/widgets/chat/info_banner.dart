import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class InfoBannerWidget extends StatelessWidget {
  final String otherUserId;
  final String myId;

  const InfoBannerWidget({
    Key? key,
    required this.otherUserId,
    required this.myId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF5FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/chat/shield_icon.svg',
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'GmarketSans'),
                    children: [
                      TextSpan(
                        text: otherUserId,
                        style: const TextStyle(color: Color(0xFF507BBF)),
                      ),
                      const TextSpan(
                        text: '님의 습득 위치와',
                        style: TextStyle(color: Color(0xFF555555)),
                      ),
                    ],
                  ),
                ),
                RichText(
                  text: TextSpan(
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontFamily: 'GmarketSans'),
                    children: [
                      TextSpan(
                        text: '$myId(나)',
                        style: const TextStyle(color: Color(0xFF507BBF)),
                      ),
                      const TextSpan(
                        text: '의 분실 위치가 일치합니다.',
                        style: TextStyle(color: Color(0xFF555555)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
