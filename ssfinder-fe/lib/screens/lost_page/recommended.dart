import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_item_model.dart';
import 'package:sumsumfinder/widgets/found/found_item_card.dart';
import 'package:sumsumfinder/screens/found_page/found_item_detail_police.dart';
import 'package:sumsumfinder/screens/found_page/found_item_detail_sumsumfinder.dart';

class Recommended extends StatelessWidget {
  final List<FoundItemModel> recommendations;

  const Recommended({Key? key, required this.recommendations}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("추천 페이지"),
      ),
      body: ListView.builder(
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final foundItem = recommendations[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => foundItem.source == '경찰청'
                        ? FoundItemDetailPolice(item: foundItem)
                        : FoundItemDetailSumsumfinder(item: foundItem),
                  ),
                );
              },
              child: FoundItemCard(item: foundItem),
            ),
          );
        },
      ),
    );
  }
}
