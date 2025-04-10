import 'package:flutter/material.dart';
import 'package:sumsumfinder/models/found_items_model.dart';
import 'package:sumsumfinder/services/found_items_api_service.dart';
import 'package:sumsumfinder/widgets/common/custom_appBar.dart';
import 'found_items_list.dart';
import '../../../screens/found/found_item_form.dart';

class FoundPage extends StatefulWidget {
  const FoundPage({Key? key}) : super(key: key);

  @override
  _FoundPageState createState() => _FoundPageState();
}

class _FoundPageState extends State<FoundPage> {
  final FoundItemsApiService _apiService = FoundItemsApiService();
  List<FoundItemListModel> _foundItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFoundItems();
  }

  Future<void> _loadFoundItems() async {
    try {
      final response = await _apiService.getMyFoundItems();
      final List<dynamic> itemsJson =
          response['data']['content'] as List<dynamic>;
      print('#### Found Items: $itemsJson');

      final items =
          itemsJson
              .map(
                (item) =>
                    FoundItemListModel.fromJson(item as Map<String, dynamic>),
              )
              .toList();

      setState(() {
        _foundItems = items;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그인이 필요합니다.')));
      print('Error: $e');
    }
  }

  void _handleItemStatusChanged(int itemId, String newStatus) {
    setState(() {
      for (int i = 0; i < _foundItems.length; i++) {
        if (_foundItems[i].id == itemId) {
          _foundItems[i] = _foundItems[i].copyWith(status: newStatus);
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '나의 습득물', isFromBottomNav: false),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : FoundItemsList(
                items: _foundItems,
                onItemStatusChanged: _handleItemStatusChanged,
              ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Material(
              elevation: 2,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FoundItemForm(),
                    ),
                  );
                },
                customBorder: const CircleBorder(),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
