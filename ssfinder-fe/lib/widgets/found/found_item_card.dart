import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_item_model.dart';

class FoundItemCard extends StatelessWidget {
  final FoundItemModel item;

  const FoundItemCard({Key? key, required this.item}) : super(key: key);

  String extractLocation(String location) {
    List<String> parts = location.split(" ");
    return parts.sublist(2, 4).join(" ");
  }

  @override
  Widget build(BuildContext context) {
    String extractedLocation = extractLocation(item.foundLocation);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            item.photo,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.category,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                item.itemName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              Text(item.source),
              Row(
                children: [
                  Text(
                    extractedLocation,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Text(
                    ' ⋅ ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    item.createdTime,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
