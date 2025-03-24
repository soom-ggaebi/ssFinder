class FoundItemModel {
  final String photo, category, itemName, source, foundLocation, createdTime, foundDate, description, color;
  final String? storageLocation;

  FoundItemModel.fromJson(Map<String, dynamic> json)
    : photo = json['photo'],
      category = json['category'],
      itemName = json['itemName'],
      source = json['source'],
      foundLocation = json['foundLocation'],
      createdTime = json['createdTime'],
      foundDate = json['foundDate'],
      storageLocation = json['storageLocation'],
      description = json['description'],
      color = json['color'];
}
