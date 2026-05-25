class LookupItem {
  const LookupItem({
    required this.id,
    required this.name,
    this.extra = const {},
  });

  final int id;
  final String name;
  final Map<String, dynamic> extra;

  int? get countryCode => _readInt(
    extra['country_code'] ??
        extra['COUNTRY_CODE'] ??
        extra['countryCode'] ??
        extra['country_id'] ??
        extra['countryId'],
  );

  int? get stateId => _readInt(
    extra['state'] ?? extra['STATE'] ?? extra['state_id'] ?? extra['stateId'],
  );

  int? get parentId => _readInt(extra['parent'] ?? extra['parent_id']);

  List<int> get dependentCasteIds => _readIntList(extra['dependentCastes']);

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    final id =
        json['id'] ??
        json['ID'] ??
        json['value'] ??
        json['VALUE'] ??
        json['countryId'] ??
        json['stateId'] ??
        json['cityId'];
    final name =
        json['name'] ??
        json['NAME'] ??
        json['label'] ??
        json['LABEL'] ??
        json['countryName'] ??
        json['stateName'] ??
        json['cityName'] ??
        json['title'] ??
        'Unknown';

    return LookupItem(
      id: int.tryParse(id.toString()) ?? 0,
      name: name.toString(),
      extra: json,
    );
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  static List<int> _readIntList(Object? value) {
    if (value is! List) return const [];
    return value
        .map((item) => int.tryParse(item.toString()))
        .whereType<int>()
        .toList(growable: false);
  }
}
