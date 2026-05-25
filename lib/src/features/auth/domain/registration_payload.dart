class RegistrationPayload {
  const RegistrationPayload({
    required this.email,
    required this.phone,
    required this.password,
    required this.fullName,
    required this.profileCreatedFor,
    required this.dateOfBirth,
    required this.gender,
    required this.maritalStatus,
    this.religionId,
    this.sectId,
    this.motherTongueId,
    this.casteId,
    this.subcasteId,
    this.kulamId,
    this.countryId,
    this.stateId,
    this.cityId,
    this.heightId,
    this.weight,
    this.educationDegreeId,
    this.occupationRoleId,
    this.employedInId,
    this.expectedSalaryId,
    this.aboutMe,
    this.matrimonyModeId,
  });

  final String email;
  final String phone;
  final String password;
  final String fullName;
  final String profileCreatedFor;
  final DateTime dateOfBirth; // now carries both date + time
  final String gender;
  final String maritalStatus;
  final int? religionId;
  final int? sectId;
  final int? motherTongueId;
  final int? casteId;
  final int? subcasteId;
  final int? kulamId;
  final int? countryId;
  final int? stateId;
  final int? cityId;
  final int? heightId;
  final int? weight;
  final int? educationDegreeId;
  final int? occupationRoleId;
  final int? employedInId;
  final int? expectedSalaryId;
  final String? aboutMe;
  final int? matrimonyModeId;

  Map<String, dynamic> toApiJson() {
    return {
      'account': {
        'email': email.trim().isEmpty ? null : email.trim(),
        'phone': phone.trim(),
        'password': password,
        'roles': ['USER'],
        'displayName': fullName.trim(),
      },
      'profile': {
        'fullname': fullName.trim(),
        'profileCreatedFor': profileCreatedFor,
        'dateOfBirth': dateOfBirth.toIso8601String(), // "1990-05-15T14:30:00.000"
        'gender': gender,
        'maritalStatus': maritalStatus,
        'religionId': religionId,
        'sectId': sectId,
        'motherTongueId': motherTongueId,
        'casteId': casteId,
        'subcasteId': subcasteId,
        'kulamId': kulamId,
        'countryId': countryId,
        'stateId': stateId,
        'cityId': cityId,
        'heightId': heightId,
        'weight': weight,
        'educationDegreeId': educationDegreeId,
        'occupationRoleId': occupationRoleId,
        'employedInId': employedInId,
        'expectedSalaryId': expectedSalaryId,
        'aboutMe': aboutMe,
        'matrimonyModeId': matrimonyModeId,
      },
    };
  }


}
