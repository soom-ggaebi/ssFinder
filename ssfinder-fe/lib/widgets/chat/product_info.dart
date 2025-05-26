import 'package:flutter/material.dart';

class ProductInfoWidget extends StatelessWidget {
  final Map<String, dynamic>? foundItemInfo;

  const ProductInfoWidget({Key? key, this.foundItemInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (foundItemInfo == null) {
      return const SizedBox.shrink(); // 정보가 없으면 아무것도 표시하지 않음
    }

    final String itemName = foundItemInfo!['name'] ?? '알 수 없음';
    final String category =
        foundItemInfo!['category'] != null
            ? "${foundItemInfo!['category']['parent_name'] ?? ''} > ${foundItemInfo!['category']['name'] ?? ''}"
            : '알 수 없음';
    final String color = foundItemInfo!['color'] ?? '';
    final String status = foundItemInfo!['status'] ?? '';
    final String imageUrl = foundItemInfo!['image'] ?? '';

    // 상태에 따른 텍스트 변환
    String statusText = '보관 중';
    if (status == 'RECEIVED') {
      statusText = '수령 완료';
    } else if (status == 'TRANSFERRED') {
      statusText = '인계 완료';
    }

    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 이미지 영역
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image:
                  imageUrl.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                      : null,
              color: Colors.grey[300],
            ),
            child:
                imageUrl.isEmpty
                    ? const Icon(Icons.image_not_supported, color: Colors.grey)
                    : null,
          ),
          const SizedBox(width: 12),
          // 정보 영역
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '카테고리: $category',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                if (color.isNotEmpty)
                  Text(
                    '색상: $color',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                Text(
                  '상태: $statusText',
                  style: TextStyle(
                    fontSize: 12,
                    color: status == 'STORED' ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.bold,
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
