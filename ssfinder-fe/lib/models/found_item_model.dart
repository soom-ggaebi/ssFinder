class FoundItemModel {
  final String photo, category, itemName, source, foundLocation, createdTime;

  FoundItemModel.fromJson(Map<String, dynamic> json)
    : photo = json['photo'],
      category = json['category'],
      itemName = json['itemName'],
      source = json['source'],
      foundLocation = json['foundLocation'],
      createdTime = json['createdTime'];
}
