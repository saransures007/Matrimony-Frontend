import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final profilePreferencesRepositoryProvider =
    Provider<ProfilePreferencesRepository>((ref) {
  return ProfilePreferencesRepository(ref.watch(apiClientProvider));
});

final myPreferencesProvider = FutureProvider<ProfilePreferencesView?>((ref) {
  return ref.watch(profilePreferencesRepositoryProvider).fetchMyPreferences();
});

class ProfilePreferencesView {
  const ProfilePreferencesView({
    this.preferredGender,
    this.preferredGenders = const [],
    this.preferredReligionIds = const [],
    this.preferredCasteIds = const [],
    this.preferredSubcasteIds = const [],
    this.preferredKulamIds = const [],
    this.preferredMotherTongueIds = const [],
    this.preferredCountryIds = const [],
    this.preferredStateIds = const [],
    this.preferredCityIds = const [],
    this.preferredEducationIds = const [],
    this.preferredOccupationIds = const [],
    this.preferredEmployedInIds = const [],
    this.preferredDietIds = const [],
    this.preferredDrinkingIds = const [],
    this.preferredSmokingIds = const [],
    this.preferredMaritalStatusIds = const [],
    this.preferredRasiIds = const [],
    this.preferredNakshatraIds = const [],
    this.preferredManglikStatusIds = const [],
    this.preferredProfilePostedByIds = const [],
    this.excludedCasteIds = const [],
    this.excludedOccupationIds = const [],
    this.excludedCityIds = const [],
    this.excludedDoshaIds = const [],
    this.minAge,
    this.maxAge,
    this.minHeightId,
    this.maxHeightId,
    this.minSalaryId,
    this.maxSalaryId,
    this.preferSameReligion = false,
    this.preferSameCaste = false,
    this.preferSameSubcaste = false,
    this.preferSameState = false,
    this.preferSameCity = false,
    this.preferSameMotherTongue = false,
    this.requireHoroscopeMatch = false,
    this.requirePhoto = false,
    this.requirePhoneVerified = false,
    this.acceptPartnerWithChildren = true,
    this.preferNoChildren = false,
    this.maxDaysInactive,
    this.minProfileCompletion,
  });

  final String? preferredGender;
  final List<String> preferredGenders;
  final List<int> preferredReligionIds;
  final List<int> preferredCasteIds;
  final List<int> preferredSubcasteIds;
  final List<int> preferredKulamIds;
  final List<int> preferredMotherTongueIds;
  final List<int> preferredCountryIds;
  final List<int> preferredStateIds;
  final List<int> preferredCityIds;
  final List<int> preferredEducationIds;
  final List<int> preferredOccupationIds;
  final List<int> preferredEmployedInIds;
  final List<int> preferredDietIds;
  final List<int> preferredDrinkingIds;
  final List<int> preferredSmokingIds;
  final List<String> preferredMaritalStatusIds;
  final List<int> preferredRasiIds;
  final List<int> preferredNakshatraIds;
  final List<String> preferredManglikStatusIds;
  final List<String> preferredProfilePostedByIds;
  final List<int> excludedCasteIds;
  final List<int> excludedOccupationIds;
  final List<int> excludedCityIds;
  final List<String> excludedDoshaIds;
  final int? minAge;
  final int? maxAge;
  final int? minHeightId;
  final int? maxHeightId;
  final int? minSalaryId;
  final int? maxSalaryId;
  final bool preferSameReligion;
  final bool preferSameCaste;
  final bool preferSameSubcaste;
  final bool preferSameState;
  final bool preferSameCity;
  final bool preferSameMotherTongue;
  final bool requireHoroscopeMatch;
  final bool requirePhoto;
  final bool requirePhoneVerified;
  final bool acceptPartnerWithChildren;
  final bool preferNoChildren;
  final int? maxDaysInactive;
  final int? minProfileCompletion;

  static int? _readInt(Object? value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  factory ProfilePreferencesView.fromJson(Map<String, dynamic> json) {
    List<int> readInts(String key) {
      final value = json[key];
      if (value is! List) return const [];
      return value
          .map((item) => int.tryParse(item.toString()))
          .whereType<int>()
          .toList(growable: false);
    }

    List<String> readStrings(String key) {
      final value = json[key];
      if (value is! List) return const [];
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
    }

    return ProfilePreferencesView(
      preferredGender: json['preferredGender']?.toString(),
      preferredGenders: readStrings('preferredGenders'),
      preferredReligionIds: readInts('preferredReligionIds'),
      preferredCasteIds: readInts('preferredCasteIds'),
      preferredSubcasteIds: readInts('preferredSubcasteIds'),
      preferredKulamIds: readInts('preferredKulamIds'),
      preferredMotherTongueIds: readInts('preferredMotherTongueIds'),
      preferredCountryIds: readInts('preferredCountryIds'),
      preferredStateIds: readInts('preferredStateIds'),
      preferredCityIds: readInts('preferredCityIds'),
      preferredEducationIds: readInts('preferredEducationIds'),
      preferredOccupationIds: readInts('preferredOccupationIds'),
      preferredEmployedInIds: readInts('preferredEmployedInIds'),
      preferredDietIds: readInts('preferredDietIds'),
      preferredDrinkingIds: readInts('preferredDrinkingIds'),
      preferredSmokingIds: readInts('preferredSmokingIds'),
      preferredMaritalStatusIds: readStrings('preferredMaritalStatusIds'),
      preferredRasiIds: readInts('preferredRasiIds'),
      preferredNakshatraIds: readInts('preferredNakshatraIds'),
      preferredManglikStatusIds: readStrings('preferredManglikStatusIds'),
      preferredProfilePostedByIds: readStrings('preferredProfilePostedByIds'),
      excludedCasteIds: readInts('excludedCasteIds'),
      excludedOccupationIds: readInts('excludedOccupationIds'),
      excludedCityIds: readInts('excludedCityIds'),
      excludedDoshaIds: readStrings('excludedDoshaIds'),
      minAge: _readInt(json['minAge']),
      maxAge: _readInt(json['maxAge']),
      minHeightId: _readInt(json['minHeightId']),
      maxHeightId: _readInt(json['maxHeightId']),
      minSalaryId: _readInt(json['minSalaryId']),
      maxSalaryId: _readInt(json['maxSalaryId']),
      preferSameReligion: json['preferSameReligion'] as bool? ?? false,
      preferSameCaste: json['preferSameCaste'] as bool? ?? false,
      preferSameSubcaste: json['preferSameSubcaste'] as bool? ?? false,
      preferSameState: json['preferSameState'] as bool? ?? false,
      preferSameCity: json['preferSameCity'] as bool? ?? false,
      preferSameMotherTongue: json['preferSameMotherTongue'] as bool? ?? false,
      requireHoroscopeMatch: json['requireHoroscopeMatch'] as bool? ?? false,
      requirePhoto: json['requirePhoto'] as bool? ?? false,
      requirePhoneVerified: json['requirePhoneVerified'] as bool? ?? false,
      acceptPartnerWithChildren:
          json['acceptPartnerWithChildren'] as bool? ?? true,
      preferNoChildren: json['preferNoChildren'] as bool? ?? false,
      maxDaysInactive: _readInt(json['maxDaysInactive']),
      minProfileCompletion: _readInt(json['minProfileCompletion']),
    );
  }

  Map<String, dynamic> toApiJson() {
    final payload = <String, dynamic>{};

    void write(String key, Object? value) {
      if (value != null) payload[key] = value;
    }

    void writeIntList(String key, List<int> value) {
      if (value.isNotEmpty) payload[key] = value;
    }

    void writeStringList(String key, List<String> value) {
      if (value.isNotEmpty) payload[key] = value;
    }

    write('preferredGender', preferredGender);
    writeStringList('preferredGenders', preferredGenders);
    writeIntList('preferredReligionIds', preferredReligionIds);
    writeIntList('preferredCasteIds', preferredCasteIds);
    writeIntList('preferredSubcasteIds', preferredSubcasteIds);
    writeIntList('preferredKulamIds', preferredKulamIds);
    writeIntList('preferredMotherTongueIds', preferredMotherTongueIds);
    writeIntList('preferredCountryIds', preferredCountryIds);
    writeIntList('preferredStateIds', preferredStateIds);
    writeIntList('preferredCityIds', preferredCityIds);
    writeIntList('preferredEducationIds', preferredEducationIds);
    writeIntList('preferredOccupationIds', preferredOccupationIds);
    writeIntList('preferredEmployedInIds', preferredEmployedInIds);
    writeIntList('preferredDietIds', preferredDietIds);
    writeIntList('preferredDrinkingIds', preferredDrinkingIds);
    writeIntList('preferredSmokingIds', preferredSmokingIds);
    writeStringList('preferredMaritalStatusIds', preferredMaritalStatusIds);
    writeIntList('preferredRasiIds', preferredRasiIds);
    writeIntList('preferredNakshatraIds', preferredNakshatraIds);
    writeStringList('preferredManglikStatusIds', preferredManglikStatusIds);
    writeStringList('preferredProfilePostedByIds', preferredProfilePostedByIds);
    writeIntList('excludedCasteIds', excludedCasteIds);
    writeIntList('excludedOccupationIds', excludedOccupationIds);
    writeIntList('excludedCityIds', excludedCityIds);
    writeStringList('excludedDoshaIds', excludedDoshaIds);
    write('minAge', minAge);
    write('maxAge', maxAge);
    write('minHeightId', minHeightId);
    write('maxHeightId', maxHeightId);
    write('minSalaryId', minSalaryId);
    write('maxSalaryId', maxSalaryId);
    write('preferSameReligion', preferSameReligion);
    write('preferSameCaste', preferSameCaste);
    write('preferSameSubcaste', preferSameSubcaste);
    write('preferSameState', preferSameState);
    write('preferSameCity', preferSameCity);
    write('preferSameMotherTongue', preferSameMotherTongue);
    write('requireHoroscopeMatch', requireHoroscopeMatch);
    write('requirePhoto', requirePhoto);
    write('requirePhoneVerified', requirePhoneVerified);
    write('acceptPartnerWithChildren', acceptPartnerWithChildren);
    write('preferNoChildren', preferNoChildren);
    write('maxDaysInactive', maxDaysInactive);
    write('minProfileCompletion', minProfileCompletion);

    return payload;
  }

  ProfilePreferencesView copyWith({
    String? preferredGender,
    List<String>? preferredGenders,
    List<int>? preferredReligionIds,
    List<int>? preferredCasteIds,
    List<int>? preferredSubcasteIds,
    List<int>? preferredKulamIds,
    List<int>? preferredMotherTongueIds,
    List<int>? preferredCountryIds,
    List<int>? preferredStateIds,
    List<int>? preferredCityIds,
    List<int>? preferredEducationIds,
    List<int>? preferredOccupationIds,
    List<int>? preferredEmployedInIds,
    List<int>? preferredDietIds,
    List<int>? preferredDrinkingIds,
    List<int>? preferredSmokingIds,
    List<String>? preferredMaritalStatusIds,
    List<int>? preferredRasiIds,
    List<int>? preferredNakshatraIds,
    List<String>? preferredManglikStatusIds,
    List<String>? preferredProfilePostedByIds,
    List<int>? excludedCasteIds,
    List<int>? excludedOccupationIds,
    List<int>? excludedCityIds,
    List<String>? excludedDoshaIds,
    int? minAge,
    int? maxAge,
    int? minHeightId,
    int? maxHeightId,
    int? minSalaryId,
    int? maxSalaryId,
    bool? preferSameReligion,
    bool? preferSameCaste,
    bool? preferSameSubcaste,
    bool? preferSameState,
    bool? preferSameCity,
    bool? preferSameMotherTongue,
    bool? requireHoroscopeMatch,
    bool? requirePhoto,
    bool? requirePhoneVerified,
    bool? acceptPartnerWithChildren,
    bool? preferNoChildren,
    int? maxDaysInactive,
    int? minProfileCompletion,
  }) {
    return ProfilePreferencesView(
      preferredGender: preferredGender ?? this.preferredGender,
      preferredGenders: preferredGenders ?? this.preferredGenders,
      preferredReligionIds: preferredReligionIds ?? this.preferredReligionIds,
      preferredCasteIds: preferredCasteIds ?? this.preferredCasteIds,
      preferredSubcasteIds: preferredSubcasteIds ?? this.preferredSubcasteIds,
      preferredKulamIds: preferredKulamIds ?? this.preferredKulamIds,
      preferredMotherTongueIds:
          preferredMotherTongueIds ?? this.preferredMotherTongueIds,
      preferredCountryIds: preferredCountryIds ?? this.preferredCountryIds,
      preferredStateIds: preferredStateIds ?? this.preferredStateIds,
      preferredCityIds: preferredCityIds ?? this.preferredCityIds,
      preferredEducationIds: preferredEducationIds ?? this.preferredEducationIds,
      preferredOccupationIds:
          preferredOccupationIds ?? this.preferredOccupationIds,
      preferredEmployedInIds:
          preferredEmployedInIds ?? this.preferredEmployedInIds,
      preferredDietIds: preferredDietIds ?? this.preferredDietIds,
      preferredDrinkingIds: preferredDrinkingIds ?? this.preferredDrinkingIds,
      preferredSmokingIds: preferredSmokingIds ?? this.preferredSmokingIds,
      preferredMaritalStatusIds:
          preferredMaritalStatusIds ?? this.preferredMaritalStatusIds,
      preferredRasiIds: preferredRasiIds ?? this.preferredRasiIds,
      preferredNakshatraIds: preferredNakshatraIds ?? this.preferredNakshatraIds,
      preferredManglikStatusIds:
          preferredManglikStatusIds ?? this.preferredManglikStatusIds,
      preferredProfilePostedByIds:
          preferredProfilePostedByIds ?? this.preferredProfilePostedByIds,
      excludedCasteIds: excludedCasteIds ?? this.excludedCasteIds,
      excludedOccupationIds:
          excludedOccupationIds ?? this.excludedOccupationIds,
      excludedCityIds: excludedCityIds ?? this.excludedCityIds,
      excludedDoshaIds: excludedDoshaIds ?? this.excludedDoshaIds,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      minHeightId: minHeightId ?? this.minHeightId,
      maxHeightId: maxHeightId ?? this.maxHeightId,
      minSalaryId: minSalaryId ?? this.minSalaryId,
      maxSalaryId: maxSalaryId ?? this.maxSalaryId,
      preferSameReligion: preferSameReligion ?? this.preferSameReligion,
      preferSameCaste: preferSameCaste ?? this.preferSameCaste,
      preferSameSubcaste: preferSameSubcaste ?? this.preferSameSubcaste,
      preferSameState: preferSameState ?? this.preferSameState,
      preferSameCity: preferSameCity ?? this.preferSameCity,
      preferSameMotherTongue:
          preferSameMotherTongue ?? this.preferSameMotherTongue,
      requireHoroscopeMatch: requireHoroscopeMatch ?? this.requireHoroscopeMatch,
      requirePhoto: requirePhoto ?? this.requirePhoto,
      requirePhoneVerified: requirePhoneVerified ?? this.requirePhoneVerified,
      acceptPartnerWithChildren:
          acceptPartnerWithChildren ?? this.acceptPartnerWithChildren,
      preferNoChildren: preferNoChildren ?? this.preferNoChildren,
      maxDaysInactive: maxDaysInactive ?? this.maxDaysInactive,
      minProfileCompletion: minProfileCompletion ?? this.minProfileCompletion,
    );
  }
}

class ProfilePreferencesRepository {
  const ProfilePreferencesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<ProfilePreferencesView?> fetchMyPreferences() async {
    final response = await _apiClient.getJson('/users/me/preferences');
    final data = response['data'];
    if (data is! Map) return null;
    return ProfilePreferencesView.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  Future<ProfilePreferencesView> saveMyPreferences(
    ProfilePreferencesView preferences,
  ) async {
    final response = await _apiClient.patchJson(
      '/users/me/preferences',
      preferences.toApiJson(),
    );
    final data = response['data'];
    if (data is Map) {
      return ProfilePreferencesView.fromJson(Map<String, dynamic>.from(data));
    }
    return preferences;
  }

  static int? _readInt(Object? value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}
