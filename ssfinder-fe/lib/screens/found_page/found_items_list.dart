import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_item_model.dart';
import 'package:sumsumfinder/service/api_service.dart';
import '../../widgets/found/found_item_card.dart';
import './found_item_detail_police.dart';
import 'found_item_detail_sumsumfinder.dart'; // 상세정보 페이지 import

class FoundItemsList extends StatefulWidget {
  const FoundItemsList({Key? key}) : super(key: key);

  @override
  _FoundItemsListState createState() => _FoundItemsListState();
}

class _FoundItemsListState extends State<FoundItemsList> {
  List<FoundItemModel> founditems = [];

  /// 데이터를 로딩 중인지 여부
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoundItems();
  }

  Future<void> _loadFoundItems() async {
    founditems = await FoundItemsListApiService.getApiData();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 스피너
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DraggableScrollableSheet(
      // 초기 높이, 최소 높이, 최대 높이
      initialChildSize: 0.05,
      minChildSize: 0.05,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10.0),
            ],
          ),
          // 목록
          child: ListView.builder(
            controller: scrollController,
            itemCount: founditems.length,
            itemBuilder: (context, index) {
              final item = founditems[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => item.source == '경찰청'
                          ? FoundItemDetailPolice(item: item)
                          : FoundItemDetailSumsumfinder(item: item),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 16.0,
                  ),
                  child: FoundItemCard(item: item),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
