import 'lookup_item.dart';

class MatrimonyMode {
  const MatrimonyMode({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    required this.isActive,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final String displayName;
  final String? description;
  final bool isActive;
  final int sortOrder;

  factory MatrimonyMode.fromJson(Map<String, dynamic> json) {
    return MatrimonyMode(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      displayName: json['displayName'] as String? ?? json['name'] as String? ?? '',
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class StaticData {
  const StaticData({
    required this.motherTongues,
    required this.countries,
    required this.states,
    required this.cities,
    required this.heights,
    required this.incomes,
    required this.education,
    required this.occupation,
    required this.employedIn,
    required this.religions,
    required this.casteGroups,
    required this.castes,
    required this.subcastes,
    required this.kulams,
    required this.sects,
    required this.matrimonyModes,
  });

  final List<LookupItem> motherTongues;
  final List<LookupItem> countries;
  final List<LookupItem> states;
  final List<LookupItem> cities;
  final List<LookupItem> heights;
  final List<LookupItem> incomes;
  final List<LookupItem> education;
  final List<LookupItem> occupation;
  final List<LookupItem> employedIn;
  final List<LookupItem> religions;
  final List<LookupItem> casteGroups;
  final List<LookupItem> castes;
  final List<LookupItem> subcastes;
  final List<LookupItem> kulams;
  final List<LookupItem> sects;
  final List<MatrimonyMode> matrimonyModes;

  factory StaticData.fromJson(Map<String, dynamic> json) {
    List<LookupItem> read(String key) {
      final value = json[key];
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((item) => LookupItem.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.id != 0)
          .toList(growable: false);
    }

    List<MatrimonyMode> readModes(String key) {
      final value = json[key];
      if (value is! List) return const [];
      return value
          .whereType<Map>()
          .map((item) => MatrimonyMode.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    }

    int sortKey(LookupItem item) {
      return int.tryParse(
            item.extra['SORTBY']?.toString() ??
                item.extra['sortBy']?.toString() ??
                item.extra['sortby']?.toString() ??
                '0',
          ) ??
          0;
    }

    final incomes = read('income')..sort((a, b) => sortKey(a).compareTo(sortKey(b)));

    return StaticData(
      motherTongues: read('mtongue'),
      countries: read('country'),
      states: read('state'),
      cities: read('city'),
      heights: read('height'),
      incomes: incomes,
      education: read('education'),
      occupation: read('occupation'),
      employedIn: read('employedIn'),
      religions: read('religion'),
      casteGroups: read('casteGroup'),
      castes: read('caste'),
      subcastes: read('subcaste'),
      kulams: read('kulam'),
      sects: read('sect'),
      matrimonyModes: readModes('matrimonyModes'),
    );
  }
}
