import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_item_model.dart';
import 'package:sumsumfinder/service/api_service.dart';
import '../../widgets/found/found_item_card.dart';

import './found_item_form.dart';

class FoundItemsList extends StatefulWidget {
  const FoundItemsList({Key? key}) : super(key: key);

  @override
  _FoundItemsListState createState() => _FoundItemsListState();
}

class _FoundItemsListState extends State<FoundItemsList> {
  List<FoundItemModel> founditems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    waitForFounditems();
  }

  Future<void> waitForFounditems() async {
    founditems = await FoundItemsListApiService.getApiData();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DraggableScrollableSheet(
      // 시작 높이, 최소 높이, 최대 높이
      initialChildSize: 0.05,
      minChildSize: 0.05,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10.0)],
              ),
              child: ListView.builder(
                controller: scrollController,
                itemCount: founditems.length,
                itemBuilder: (context, index) {
                  final item = founditems[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 16.0,
                    ),
                    child: FoundItemCard(
                      photo: item.photo,
                      category: item.category,
                      itemName: item.itemName,
                      source: item.source,
                      foundLocation: item.foundLocation,
                      createdTime: item.createdTime,
                    ),
                  );
                },
              ),
            ),

            Positioned(
              top: 20,
              right: 20,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FoundItemForm()),
                  );
                },
                borderRadius: BorderRadius.circular(30),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
