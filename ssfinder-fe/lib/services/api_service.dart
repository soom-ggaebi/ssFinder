import 'dart:convert';
import 'package:sumsumfinder/models/lost_item_model.dart';
import 'package:sumsumfinder/models/found_item_model.dart';
import 'package:flutter/services.dart' show rootBundle;

class FoundItemsApiService {
  static Future<List<FoundItemListModel>> getApiData() async {
    List<FoundItemListModel> itemInstances = [];
    final String response = await rootBundle.loadString(
      'assets/found_items_dummy_data.json',
    );

    final List<dynamic> items = jsonDecode(response);
    for (var item in items) {
      itemInstances.add(FoundItemListModel.fromJson(item));
    }
    return itemInstances;
  }
}

class FoundItemsListApiService {
  static Future<List<FoundItemListModel>> getApiData() async {
    final String response = await rootBundle.loadString(
      'assets/found_items_list_dummy_data.json',
    );

    final List<dynamic> items = jsonDecode(response);

    List<FoundItemListModel> itemInstances =
        items.map((item) => FoundItemListModel.fromJson(item)).toList();

    return itemInstances;
  }
}

class LostItemsApiService {
  static Future<List<LostItemModel>> getApiData() async {
    List<LostItemModel> itemInstances = [];
    final String response = await rootBundle.loadString(
      'assets/lost_items_dummy_data.json',
    );

    final List<dynamic> items = jsonDecode(response);
    for (var item in items) {
      itemInstances.add(LostItemModel.fromJson(item));
    }
    return itemInstances;
  }
}

class LostItemsListApiService {
  static Future<List<FoundItemListModel>> getApiData() async {
    final String response = await rootBundle.loadString(
      'assets/lost_items_list_dummy_data.json',
    );

    final List<dynamic> items = jsonDecode(response);

    List<FoundItemListModel> itemInstances =
        items.map((item) => FoundItemListModel.fromJson(item)).toList();

    return itemInstances;
  }
}
