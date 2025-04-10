import 'package:flutter/material.dart';

class Recommended extends StatelessWidget {
  final int lostItemId;

  const Recommended({Key? key, required this.lostItemId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("추천 페이지")),
      body: Center(
        child: Text(
          "추천 데이터를 불러올 분실물 ID: $lostItemId",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}