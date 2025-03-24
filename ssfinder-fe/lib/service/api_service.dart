import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sumsumfinder/models/lost_item_model.dart';
import 'package:sumsumfinder/models/found_item_model.dart';
import 'package:sumsumfinder/models/model.dart';

import 'package:flutter/services.dart' show rootBundle;

class ApiService {
  static const String baseUrl = "";

  static Future<List<ExModel>> getApiData() async {
    List<ExModel> exInstances = [];
    final url = Uri.parse('$baseUrl');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> res = jsonDecode(response.body);
      for (var r in res) {
        exInstances.add(ExModel.fromJson(r));
      }
      return exInstances;
    }
    throw Error();
  }
}

class FoundItemsListApiService {
  static Future<List<FoundItemModel>> getApiData() async {
    List<FoundItemModel> itemInstances = [];
    final String response = await rootBundle.loadString(
      'assets/found_items_list_dummy_data.json',
    );

    final List<dynamic> items = jsonDecode(response);
    for (var item in items) {
      itemInstances.add(FoundItemModel.fromJson(item));
    }
    return itemInstances;
  }
}

class LostItemsListApiService {
  static Future<List<LostItemModel>> getApiData() async {
    List<LostItemModel> itemInstances = [];
    final String response = await rootBundle.loadString(
      'assets/lost_items_list_dummy_data.json',
    );

    final List<dynamic> items = jsonDecode(response);
    for (var item in items) {
      itemInstances.add(LostItemModel.fromJson(item));
    }
    return itemInstances;
  }
}
