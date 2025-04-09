import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_items_model.dart';
import 'package:sumsumfinder/services/found_items_api_service.dart';

class FoundItemCard extends StatefulWidget {
  final FoundItemListModel item;
  final bool isLoggedIn;

  const FoundItemCard({Key? key, required this.item, required this.isLoggedIn})
      : super(key: key);

  @override
  _FoundItemCardState createState() => _FoundItemCardState();
}

class _FoundItemCardState extends State<FoundItemCard> {
  late FoundItemListModel item;
  final FoundItemsApiService _apiService = FoundItemsApiService();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    item = widget.item;
  }

  String extractLocation(String location) {
    List<String> parts = location.split(" ");
    if (parts.length >= 4) {
      return parts.sublist(2, 4).join(" ");
    }
    return location;
  }

  Future<void> _toggleBookmark() async {
    if (_processing) return;
    setState(() {
      _processing = true;
    });
    try {
      if (item.bookmarked == true) {
        await _apiService.deleteBookmark(foundId: item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('북마크가 삭제되었습니다.')),
        );
        setState(() {
          item = item.copyWith(bookmarked: false);
        });
      } else {
        await _apiService.bookmarkFoundItem(foundId: item.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('북마크가 등록되었습니다.')),
        );
        setState(() {
          item = item.copyWith(bookmarked: true);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('북마크 처리 중 오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayLocation;
    if (item.type == "경찰청") {
      displayLocation = (item.storageLocation != null &&
              item.storageLocation!.trim().isNotEmpty)
          ? item.storageLocation!
          : item.foundLocation;
    } else {
      displayLocation = extractLocation(item.foundLocation);
    }

    final cardContent = Row(
      children: [
        // 이미지 영역
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: item.image != null
              ? Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(item.image!),
                      fit: BoxFit.cover,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (item.minorCategory == null)
                          ? "${item.majorCategory}"
                          : "${item.majorCategory} > ${item.minorCategory}",
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  if (widget.isLoggedIn)
                    IconButton(
                      icon: _processing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              item.bookmarked == true
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: item.bookmarked == true ? Colors.blue : Colors.grey,
                            ),
                      onPressed: _toggleBookmark,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
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

    return Stack(
      children: [
        cardContent,
        if (item.status != "STORED") ...[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
