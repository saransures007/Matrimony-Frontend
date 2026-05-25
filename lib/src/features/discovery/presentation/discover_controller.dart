import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../account/data/profile_preferences_repository.dart';
import '../data/matches_repository.dart';
import '../domain/match_profile.dart';

class DiscoverFilters {
  const DiscoverFilters({
    required this.ageRange,
    required this.onlyVerified,
    required this.premiumOnly,
    required this.genders,
    required this.maritalStatuses,
    required this.countryIds,
    required this.stateIds,
    required this.cityIds,
    required this.religionIds,
    required this.casteIds,
    required this.subcasteIds,
    required this.kulamIds,
    required this.motherTongueIds,
    required this.educationDegreeIds,
    required this.occupationRoleIds,
    required this.employedInIds,
    this.minHeightId,
    this.maxHeightId,
  });

  final RangeValues ageRange;
  final bool onlyVerified;
  final bool premiumOnly;
  final List<String> genders;
  final List<String> maritalStatuses;
  final List<int> countryIds;
  final List<int> stateIds;
  final List<int> cityIds;
  final List<int> religionIds;
  final List<int> casteIds;
  final List<int> subcasteIds;
  final List<int> kulamIds;
  final List<int> motherTongueIds;
  final List<int> educationDegreeIds;
  final List<int> occupationRoleIds;
  final List<int> employedInIds;
  final int? minHeightId;
  final int? maxHeightId;

  const DiscoverFilters.defaults()
      : ageRange = const RangeValues(21, 35),
        onlyVerified = false,
        premiumOnly = false,
        genders = const [],
        maritalStatuses = const [],
        countryIds = const [],
        stateIds = const [],
        cityIds = const [],
        religionIds = const [],
        casteIds = const [],
        subcasteIds = const [],
        kulamIds = const [],
        motherTongueIds = const [],
        educationDegreeIds = const [],
        occupationRoleIds = const [],
        employedInIds = const [],
        minHeightId = null,
        maxHeightId = null;

  int? get religionId => religionIds.isEmpty ? null : religionIds.first;
  int? get educationDegreeId =>
      educationDegreeIds.isEmpty ? null : educationDegreeIds.first;
  int? get occupationRoleId =>
      occupationRoleIds.isEmpty ? null : occupationRoleIds.first;
  int? get heightId => minHeightId ?? maxHeightId;

  DiscoverFilters copyWith({
    RangeValues? ageRange,
    bool? onlyVerified,
    bool? premiumOnly,
    List<String>? genders,
    List<String>? maritalStatuses,
    List<int>? countryIds,
    List<int>? stateIds,
    List<int>? cityIds,
    List<int>? religionIds,
    List<int>? casteIds,
    List<int>? subcasteIds,
    List<int>? kulamIds,
    List<int>? motherTongueIds,
    List<int>? educationDegreeIds,
    List<int>? occupationRoleIds,
    List<int>? employedInIds,
    int? minHeightId,
    int? maxHeightId,
  }) {
    return DiscoverFilters(
      ageRange: ageRange ?? this.ageRange,
      onlyVerified: onlyVerified ?? this.onlyVerified,
      premiumOnly: premiumOnly ?? this.premiumOnly,
      genders: genders ?? this.genders,
      maritalStatuses: maritalStatuses ?? this.maritalStatuses,
      countryIds: countryIds ?? this.countryIds,
      stateIds: stateIds ?? this.stateIds,
      cityIds: cityIds ?? this.cityIds,
      religionIds: religionIds ?? this.religionIds,
      casteIds: casteIds ?? this.casteIds,
      subcasteIds: subcasteIds ?? this.subcasteIds,
      kulamIds: kulamIds ?? this.kulamIds,
      motherTongueIds: motherTongueIds ?? this.motherTongueIds,
      educationDegreeIds: educationDegreeIds ?? this.educationDegreeIds,
      occupationRoleIds: occupationRoleIds ?? this.occupationRoleIds,
      employedInIds: employedInIds ?? this.employedInIds,
      minHeightId: minHeightId ?? this.minHeightId,
      maxHeightId: maxHeightId ?? this.maxHeightId,
    );
  }
}

final discoverFiltersProvider =
    StateNotifierProvider<DiscoverFiltersController, DiscoverFilters>(
  (ref) => DiscoverFiltersController(),
);

final filteredDiscoverProfilesProvider = Provider<List<MatchProfile>>((ref) {
  final profilesAsync = ref.watch(matchesProvider);
  final filters = ref.watch(discoverFiltersProvider);

  return profilesAsync.maybeWhen(
    data: (profiles) {
      return profiles.where((profile) {
        final age = profile.age;
        if (age < filters.ageRange.start || age > filters.ageRange.end) {
          return false;
        }

        if (filters.onlyVerified && profile.pictures.isEmpty) {
          return false;
        }

        if (filters.premiumOnly && profile.matrimonyModeId != 2) {
          return false;
        }

        if (_hasValues(filters.genders) &&
            (profile.gender.isEmpty || !filters.genders.contains(profile.gender))) {
          return false;
        }

        if (_hasValues(filters.maritalStatuses) &&
            (profile.maritalStatus.isEmpty ||
                !filters.maritalStatuses.contains(profile.maritalStatus))) {
          return false;
        }

        if (_hasValues(filters.countryIds) &&
            (profile.countryId == null ||
                !filters.countryIds.contains(profile.countryId))) {
          return false;
        }

        if (_hasValues(filters.stateIds) &&
            filters.countryIds.isNotEmpty &&
            (profile.stateId == null || !filters.stateIds.contains(profile.stateId))) {
          return false;
        }

        if (_hasValues(filters.cityIds) &&
            filters.countryIds.isNotEmpty &&
            (profile.cityId == null || !filters.cityIds.contains(profile.cityId))) {
          return false;
        }

        if (_hasValues(filters.religionIds) &&
            (profile.religionId == null ||
                !filters.religionIds.contains(profile.religionId))) {
          return false;
        }

        if (_hasValues(filters.casteIds) &&
            (profile.casteId == null || !filters.casteIds.contains(profile.casteId))) {
          return false;
        }

        if (_hasValues(filters.subcasteIds) &&
            (profile.subcasteId == null ||
                !filters.subcasteIds.contains(profile.subcasteId))) {
          return false;
        }

        if (_hasValues(filters.kulamIds) &&
            (profile.kulamId == null || !filters.kulamIds.contains(profile.kulamId))) {
          return false;
        }

        if (_hasValues(filters.motherTongueIds) &&
            (profile.motherTongueId == null ||
                !filters.motherTongueIds.contains(profile.motherTongueId))) {
          return false;
        }

        if (_hasValues(filters.educationDegreeIds) &&
            (profile.educationDegreeId == null ||
                !filters.educationDegreeIds.contains(profile.educationDegreeId))) {
          return false;
        }

        if (_hasValues(filters.occupationRoleIds) &&
            (profile.occupationRoleId == null ||
                !filters.occupationRoleIds.contains(profile.occupationRoleId))) {
          return false;
        }

        if (_hasValues(filters.employedInIds) &&
            (profile.employedInId == null ||
                !filters.employedInIds.contains(profile.employedInId))) {
          return false;
        }

        if (filters.minHeightId != null &&
            profile.heightId != null &&
            profile.heightId! < filters.minHeightId!) {
          return false;
        }

        if (filters.maxHeightId != null &&
            profile.heightId != null &&
            profile.heightId! > filters.maxHeightId!) {
          return false;
        }

        return true;
      }).toList(growable: false);
    },
    orElse: () => const [],
  );
});

class DiscoverFiltersController extends StateNotifier<DiscoverFilters> {
  DiscoverFiltersController() : super(const DiscoverFilters.defaults());

  void applyPreferences(ProfilePreferencesView preferences) {
    state = state.copyWith(
      ageRange: RangeValues(
        (preferences.minAge ?? state.ageRange.start.toInt()).toDouble(),
        (preferences.maxAge ?? state.ageRange.end.toInt()).toDouble(),
      ),
      onlyVerified: preferences.requirePhoto || preferences.requirePhoneVerified,
      genders: preferences.preferredGenders,
      maritalStatuses: preferences.preferredMaritalStatusIds,
      countryIds: preferences.preferredCountryIds,
      stateIds: preferences.preferredStateIds,
      cityIds: preferences.preferredCityIds,
      religionIds: preferences.preferredReligionIds,
      casteIds: preferences.preferredCasteIds,
      subcasteIds: preferences.preferredSubcasteIds,
      kulamIds: preferences.preferredKulamIds,
      motherTongueIds: preferences.preferredMotherTongueIds,
      educationDegreeIds: preferences.preferredEducationIds,
      occupationRoleIds: preferences.preferredOccupationIds,
      employedInIds: preferences.preferredEmployedInIds,
      minHeightId: preferences.minHeightId,
      maxHeightId: preferences.maxHeightId,
    );
  }

  void setAgeRange(RangeValues range) {
    state = state.copyWith(ageRange: range);
  }

  void setGenders(List<String> genders) {
    state = state.copyWith(genders: genders);
  }

  void setMaritalStatuses(List<String> maritalStatuses) {
    state = state.copyWith(maritalStatuses: maritalStatuses);
  }

  void setOnlyVerified(bool value) {
    state = state.copyWith(onlyVerified: value);
  }

  void setPremiumOnly(bool value) {
    state = state.copyWith(premiumOnly: value);
  }

  void setReligion(int? religionId) {
    state = state.copyWith(
      religionIds: religionId == null ? const [] : [religionId],
    );
  }

  void setReligionIds(List<int> religionIds) {
    state = state.copyWith(religionIds: religionIds);
  }

  void setEducation(int? educationDegreeId) {
    state = state.copyWith(
      educationDegreeIds: educationDegreeId == null ? const [] : [educationDegreeId],
    );
  }

  void setEducationIds(List<int> educationDegreeIds) {
    state = state.copyWith(educationDegreeIds: educationDegreeIds);
  }

  void setOccupation(int? occupationRoleId) {
    state = state.copyWith(
      occupationRoleIds: occupationRoleId == null ? const [] : [occupationRoleId],
    );
  }

  void setOccupationIds(List<int> occupationRoleIds) {
    state = state.copyWith(occupationRoleIds: occupationRoleIds);
  }

  void setHeight(int? heightId) {
    state = state.copyWith(
      minHeightId: heightId,
      maxHeightId: heightId,
    );
  }

  void setCountryIds(List<int> countryIds) {
    state = state.copyWith(countryIds: countryIds);
  }

  void setStateIds(List<int> stateIds) {
    state = state.copyWith(stateIds: stateIds);
  }

  void setCityIds(List<int> cityIds) {
    state = state.copyWith(cityIds: cityIds);
  }

  void reset() {
    state = const DiscoverFilters.defaults();
  }
}

bool _hasValues<T>(List<T> values) => values.isNotEmpty;
