import 'package:flutter/material.dart';

class CustomDraggableSheet extends StatelessWidget {
  final Widget Function(ScrollController) builder;

  const CustomDraggableSheet({Key? key, required this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      // 시작할 때 보여질 시트의 높이
      initialChildSize: 0.05,
      // 최소 높이
      minChildSize: 0.05,
      // 최대 높이
      maxChildSize: 0.8,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
          ),
          child: builder(scrollController),
        );
      },
    );
  }
}
