import 'package:flutter/material.dart';

class FoundItemCard extends StatelessWidget {
  final String photo;
  final String category;
  final String itemName;
  final String source;
  final String foundLocation;
  final String createdTime;

  const FoundItemCard({
    required this.photo,
    required this.category,
    required this.itemName,
    required this.source,
    required this.foundLocation,
    required this.createdTime,
    Key? key,
  }) : super(key: key);

  String extractLocation(String location) {
    List<String> parts = location.split(" ");
    return parts.sublist(2, 4).join(" ");
  }

  @override
  Widget build(BuildContext context) {
    String extractedLocation = extractLocation(foundLocation);

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.asset(
            'assets/images/founditem.png',
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
                category,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                itemName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              Text(source),
              Row(
                children: [
                  Text(
                    extractedLocation,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    ' ⋅ ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    createdTime,
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
