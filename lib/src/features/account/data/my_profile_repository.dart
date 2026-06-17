import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../media/data/profile_picture_repository.dart';

final myProfileRepositoryProvider = Provider<MyProfileRepository>((ref) {
  return MyProfileRepository(
    ref.watch(apiClientProvider),
    ref.watch(profilePictureRepositoryProvider),
  );
});

final myProfileProvider = FutureProvider<MyProfileView>((ref) {
  return ref.watch(myProfileRepositoryProvider).fetchMyProfile();
});

class MyProfileView {
  const MyProfileView({
    required this.accountId,
    required this.displayName,
    required this.primaryEmail,
    required this.primaryPhone,
    required this.profile,
    required this.primaryPhotoUrl,
    required this.photosCount,
    required this.approvedPhotosCount,
    required this.profileCompletion,
  });

  final String accountId;
  final String displayName;
  final String? primaryEmail;
  final String? primaryPhone;
  final MyProfileDetails profile;
  final String? primaryPhotoUrl;
  final int photosCount;
  final int approvedPhotosCount;
  final int profileCompletion;
}

class MyProfileDetails {
  const MyProfileDetails({
    required this.profileId,
    required this.fullname,
    required this.profileCreatedFor,
    required this.dateOfBirth,
    required this.gender,
    required this.maritalStatus,
    required this.profileStatus,
    required this.isSearchable,
    required this.visibility,
    required this.aboutMe,
    required this.heightId,
    required this.weight,
    required this.educationDegreeId,
    required this.occupationRoleId,
    required this.employedInId,
    required this.expectedSalaryId,
    required this.religionId,
    required this.casteId,
    required this.subcasteId,
    required this.kulamId,
    required this.motherTongueId,
    required this.countryId,
    required this.stateId,
    required this.cityId,
  });

  final String profileId;
  final String fullname;
  final String profileCreatedFor;
  final DateTime dateOfBirth;
  final String gender;
  final String maritalStatus;
  final String profileStatus;
  final bool isSearchable;
  final String visibility;
  final String? aboutMe;
  final int? heightId;
  final num? weight;
  final int? educationDegreeId;
  final int? occupationRoleId;
  final int? employedInId;
  final int? expectedSalaryId;
  final int? religionId;
  final int? casteId;
  final int? subcasteId;
  final int? kulamId;
  final int? motherTongueId;
  final int? countryId;
  final int? stateId;
  final int? cityId;

  factory MyProfileDetails.fromJson(Map<String, dynamic> json) {
    return MyProfileDetails(
      profileId: json['profileId'] as String? ?? '',
      fullname: json['fullname'] as String? ?? '',
      profileCreatedFor: json['profileCreatedFor'] as String? ?? '',
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? '') ??
          DateTime(2000),
      gender: json['gender'] as String? ?? '',
      maritalStatus: json['maritalStatus'] as String? ?? '',
      profileStatus: json['profileStatus'] as String? ?? 'Active',
      isSearchable: json['isSearchable'] as bool? ?? true,
      visibility: json['visibility'] as String? ?? 'Public',
      aboutMe: json['aboutMe'] as String?,
      heightId: json['heightId'] as int?,
      weight: json['weight'] as num?,
      educationDegreeId: json['educationDegreeId'] as int?,
      occupationRoleId: json['occupationRoleId'] as int?,
      employedInId: json['employedInId'] as int?,
      expectedSalaryId: json['expectedSalaryId'] as int?,
      religionId: json['religionId'] as int?,
      casteId: json['casteId'] as int?,
      subcasteId: json['subcasteId'] as int?,
      kulamId: json['kulamId'] as int?,
      motherTongueId: json['motherTongueId'] as int?,
      countryId: json['countryId'] as int?,
      stateId: json['stateId'] as int?,
      cityId: json['cityId'] as int?,
    );
  }

  int get age {
    final now = DateTime.now();
    var years = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      years--;
    }
    return years;
  }
}

class MyProfileRepository {
  const MyProfileRepository(this._apiClient, this._pictureRepository);

  final ApiClient _apiClient;
  final ProfilePictureRepository _pictureRepository;

  Future<MyProfileView> fetchMyProfile() async {
    final response = await _apiClient.getJson('/users/me');
    final pictures = await _pictureRepository.fetchProfilePictures();
    return _buildProfileView(response, pictures);
  }

  Future<MyProfileView> updateMyProfile(
    String accountId,
    Map<String, dynamic> updates,
  ) async {
    await _apiClient.putJson('/users/$accountId', updates);
    return fetchMyProfile();
  }

  MyProfileView _buildProfileView(
    Map<String, dynamic> response,
    List<ProfilePicture> pictures,
  ) {
    final data = response['data'];
    final payloadSource = data is Map ? data : response;
    final payload = Map<String, dynamic>.from(payloadSource);

    final profileSource = payload['profile'] is Map
        ? payload['profile'] as Map
        : payload;
    final profileJson = Map<String, dynamic>.from(profileSource);

    final accountSource = payload['account'] is Map
        ? payload['account'] as Map
        : const <String, dynamic>{};
    final accountJson = Map<String, dynamic>.from(accountSource);

    final primaryPhoto = pictures.where((item) => item.isProfilePic).isNotEmpty
        ? pictures.firstWhere((item) => item.isProfilePic).url
        : pictures.isNotEmpty
            ? pictures.first.url
            : null;

    return MyProfileView(
      accountId: payload['accountId'] as String? ??
          accountJson['accountId'] as String? ??
          accountJson['account_id'] as String? ??
          '',
      displayName: payload['displayName'] as String? ??
          payload['display_name'] as String? ??
          accountJson['displayName'] as String? ??
          accountJson['display_name'] as String? ??
          profileJson['fullname'] as String? ??
          '',
      primaryEmail: _normalizeText(
        payload['primaryEmail'] ??
            payload['primary_email'] ??
            payload['email'] ??
            accountJson['primaryEmail'] ??
            accountJson['primary_email'] ??
            accountJson['email'] ??
            profileJson['primaryEmail'] ??
            profileJson['primary_email'] ??
            profileJson['email'],
      ),
      primaryPhone: _normalizeText(
        payload['primaryPhone'] ??
            payload['primary_phone'] ??
            payload['phone'] ??
            accountJson['primaryPhone'] ??
            accountJson['primary_phone'] ??
            accountJson['phone'] ??
            profileJson['primaryPhone'] ??
            profileJson['primary_phone'] ??
            profileJson['phone'],
      ),
      profile: MyProfileDetails.fromJson(profileJson),
      primaryPhotoUrl: primaryPhoto,
      photosCount: pictures.length,
      approvedPhotosCount: pictures.where((item) => item.isApproved).length,
      profileCompletion: _completionScore(profileJson, pictures.isNotEmpty),
    );
  }

  String? _normalizeText(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return text;
  }

  int _completionScore(Map<String, dynamic> profileJson, bool hasPhoto) {
    final checks = <bool>[
      (profileJson['fullname'] as String? ?? '').isNotEmpty,
      (profileJson['aboutMe'] as String? ?? '').isNotEmpty,
      profileJson['heightId'] != null,
      profileJson['educationDegreeId'] != null,
      profileJson['occupationRoleId'] != null,
      profileJson['countryId'] != null,
      hasPhoto,
    ];
    final score = (checks.where((value) => value).length / checks.length * 100)
        .round();
    return score.clamp(0, 100);
  }
}
