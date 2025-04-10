import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_items_model.dart';

class FoundItemCard extends StatelessWidget {
  final FoundItemListModel item;

  const FoundItemCard({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = item.status == "RECEIVED";
    final Color labelBackground =
        isCompleted ? Colors.lightGreen[100]! : Colors.blue[100]!;
    final Color labelBorder = isCompleted ? Colors.green : Colors.blue;
    final Color labelTextColor = isCompleted ? Colors.green : Colors.blue;
    final String labelText = isCompleted ? '돌려준물건' : '보관중인물건';

    final contentRow = Row(
      children: [
        // 이미지 영역
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child:
              item.image != null
                  ? Image.network(
                    item.image!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[500],
                        ),
                      );
                    },
                  )
                  : Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey[500]),
                  ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 정보
              Text(
                (item.minorCategory == null || item.minorCategory!.isEmpty)
                    ? "${item.majorCategory ?? ''}"
                    : "${item.majorCategory ?? ''} > ${item.minorCategory}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              // 습득물 이름
              Text(
                item.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              // 습득 장소 정보
              Text(
                '${item.foundLocation}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              // 습득 일시 정보
              Text(
                '${item.createdTime.substring(0, 10)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ],
    );

    Widget cardContent = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2F9),
        border: const Border(bottom: BorderSide(color: Colors.grey)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: contentRow,
    );

    if (isCompleted) {
      cardContent = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: cardContent,
      );
    }

    return Stack(
      children: [
        cardContent,
        if (isCompleted)
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: labelBackground,
              border: Border.all(color: labelBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              labelText,
              style: TextStyle(fontSize: 12, color: labelTextColor),
            ),
          ),
        ),
      ],
    );
  }
}
