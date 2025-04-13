import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_items_model.dart';
import 'package:sumsumfinder/widgets/found/found_item_card.dart';
import 'package:sumsumfinder/screens/found/found_item_detail_police.dart';
import 'package:sumsumfinder/screens/found/found_item_detail_sumsumfinder.dart';
import 'package:sumsumfinder/services/ai_api_service.dart'; // ai_api_service.dart 파일의 경로 확인

class Recommended extends StatefulWidget {
  final int lostItemId;

  const Recommended({Key? key, required this.lostItemId}) : super(key: key);

  @override
  _RecommendedState createState() => _RecommendedState();
}

class _RecommendedState extends State<Recommended> {
  late Future<List<FoundItemListModel>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = _fetchRecommendations();
  }

  Future<List<FoundItemListModel>> _fetchRecommendations() async {
    try {
      final apiService = AiApiService();
      final response = await apiService.getMatchedItems(lostItemId: widget.lostItemId);

      List<dynamic> data = response['data'];

      List<FoundItemListModel> recommendations = data
          .map((json) => FoundItemListModel.fromJson(json as Map<String, dynamic>))
          .toList();
      print(recommendations);
      return recommendations;
    } catch (e) {
      print("추천 데이터를 불러오는 중 에러 발생: $e");
      throw Exception("추천 데이터를 불러오는 데 실패했습니다.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("추천 페이지")),
      body: FutureBuilder<List<FoundItemListModel>>(
        future: _recommendationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          else if (snapshot.hasError) {
            return Center(child: Text("오류 발생: ${snapshot.error}"));
          }
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("추천된 항목이 없습니다."));
          } else {
            final recommendations = snapshot.data!;
            return ListView.builder(
              itemCount: recommendations.length,
              itemBuilder: (context, index) {
                final foundItem = recommendations[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              foundItem.type == '경찰청'
                                  ? FoundItemDetailPolice(id: foundItem.id)
                                  : FoundItemDetailSumsumfinder(id: foundItem.id),
                        ),
                      );
                    },
                    child: FoundItemCard(item: foundItem, isLoggedIn: true),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
