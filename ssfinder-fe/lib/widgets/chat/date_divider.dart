import 'package:flutter/material.dart';

class DateDividerWidget extends StatelessWidget {
  final String date;

  const DateDividerWidget({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              date,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.grey[600]),
            ),
          ),
          const Expanded(child: Divider(color: Colors.grey)),
        ],
      ),
    );
  }
}
