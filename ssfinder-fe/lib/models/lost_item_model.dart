class LostItemModel {
  final String photo, category, itemName, lostDate, lostLocation, color;
  final Map<String, dynamic> recommended;
  final bool status, isNotificationOn;

  LostItemModel.fromJson(Map<String, dynamic> json)
      : photo = json['photo'],
        category = json['category'],
        color = json['color'],
        itemName = json['itemName'],
        lostDate = json['lostDate'],
        lostLocation = json['lostLocation'],
        status = json['status'],
        recommended = json['recommended'],
        isNotificationOn = json['isNotificationOn'];
}
