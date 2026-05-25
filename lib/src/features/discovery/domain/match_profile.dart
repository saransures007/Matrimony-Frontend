class MatchProfile {
  const MatchProfile({
    required this.profileId,
    required this.fullname,
    required this.profileCreatedFor,
    required this.dateOfBirth,
    required this.gender,
    required this.maritalStatus,
    this.aboutMe,
    this.matrimonyModeId,
    this.cityId,
    this.educationDegreeId,
    this.occupationRoleId,
    this.heightId,
    this.religionId,
    this.casteId,
    this.imageUrl,
    this.countryId,
    this.stateId,
    this.motherTongueId,
    this.subcasteId,
    this.kulamId,
    this.employedInId,
    this.expectedSalaryId,
    this.weight,
    this.pictures = const [],
  });

  final String profileId;
  final String fullname;
  final String profileCreatedFor;
  final DateTime dateOfBirth;
  final String gender;
  final String maritalStatus;
  final String? aboutMe;
  final int? matrimonyModeId;
  final int? cityId;
  final int? educationDegreeId;
  final int? occupationRoleId;
  final int? heightId;
  final int? religionId;
  final int? casteId;
  final String? imageUrl;
  final int? countryId;
  final int? stateId;
  final int? motherTongueId;
  final int? subcasteId;
  final int? kulamId;
  final int? employedInId;
  final int? expectedSalaryId;
  final num? weight;
  final List<String> pictures;

  factory MatchProfile.fromJson(Map<String, dynamic> json) {
    return MatchProfile(
      profileId: json['profileId'] as String? ?? '',
      fullname: json['fullname'] as String? ?? '',
      profileCreatedFor: json['profileCreatedFor'] as String? ?? '',
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString()) ?? DateTime(2000)
          : DateTime(2000),
      gender: json['gender'] as String? ?? '',
      maritalStatus: json['maritalStatus'] as String? ?? '',
      aboutMe: json['aboutMe'] as String?,
      matrimonyModeId: json['matrimonyModeId'] as int?,
      cityId: json['cityId'] as int?,
      educationDegreeId: json['educationDegreeId'] as int?,
      occupationRoleId: json['occupationRoleId'] as int?,
      heightId: json['heightId'] as int?,
      religionId: json['religionId'] as int?,
      casteId: json['casteId'] as int?,
      imageUrl: json['imageUrl'] as String?,
      countryId: json['countryId'] as int?,
      stateId: json['stateId'] as int?,
      motherTongueId: json['motherTongueId'] as int?,
      subcasteId: json['subcasteId'] as int?,
      kulamId: json['kulamId'] as int?,
      employedInId: json['employedInId'] as int?,
      expectedSalaryId: json['expectedSalaryId'] as int?,
      weight: json['weight'] as num?,
      pictures: (json['pictures'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => item['url']?.toString() ?? '')
          .where((url) => url.isNotEmpty)
          .toList(growable: false),
    );
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }
}
