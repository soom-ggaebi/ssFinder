class FoundItemModel {
  final String photo,
      category,
      itemName,
      source,
      foundLocation,
      createdTime,
      foundDate,
      description,
      color;
  final String? storageLocation, userName;
  final int id;

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
      color = json['color'],
      id = json['id'] ?? 0, // 추가
      userName = json['userName']; // 추가
}
