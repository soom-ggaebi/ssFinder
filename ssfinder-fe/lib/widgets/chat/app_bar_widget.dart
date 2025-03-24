import 'package:flutter/material.dart';
import './option_popups/main.dart';

class ChatAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBackPressed;
  final VoidCallback onMorePressed;

  const ChatAppBar({
    Key? key,
    required this.title,
    required this.onBackPressed,
    required this.onMorePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_rounded,
              color: Colors.black54,
            ),
            onPressed: onBackPressed,
          ),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Color(0xFF3D3D3D)),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => MainOptionsPopup(),
              );
            },
          ),
        ],
      ),
    );
  }
}
