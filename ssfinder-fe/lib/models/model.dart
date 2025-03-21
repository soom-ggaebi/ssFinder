class ExModel {
  final String str, str2, str3;

  ExModel.fromJson(Map<String, dynamic> json)
    : str = json['str'],
      str2 = json['str2'],
      str3 = json['str3'];
}
