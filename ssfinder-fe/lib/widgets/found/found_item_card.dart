import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_items_model.dart';

class FoundItemCard extends StatelessWidget {
  final FoundItemListModel item;

  const FoundItemCard({Key? key, required this.item}) : super(key: key);

  String extractLocation(String location) {
    List<String> parts = location.split(" ");
    if (parts.length >= 4) {
      return parts.sublist(2, 4).join(" ");
    }
    return location;
  }

  @override
  Widget build(BuildContext context) {
    String displayLocation;

    if (item.type == "경찰청") {
      displayLocation =
          (item.storageLocation != null &&
                  item.storageLocation!.trim().isNotEmpty)
              ? item.storageLocation!
              : item.foundLocation;
    } else {
      displayLocation = extractLocation(item.foundLocation);
    }

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child:
              item.image != null
                  ? Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(
                          item.image!,
                        ), // NetworkImage로 이미지 로드
                        fit: BoxFit.cover, // 이미지를 컨테이너에 맞게 채움
                      ),
                    ),
                  )
                  : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${item.majorCategory} > ${item.minorCategory}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              Text(
                item.type,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
              Row(
                children: [
                  Text(
                    displayLocation,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const Text(
                    ' ⋅ ',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    item.createdTime.substring(0, 10),
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
