class InterestProfile {
  const InterestProfile({
    required this.profileId,
    required this.fullname,
    this.imageUrl,
    this.aboutMe,
  });

  final String profileId;
  final String fullname;
  final String? imageUrl;
  final String? aboutMe;

  factory InterestProfile.fromJson(Map<String, dynamic> json) {
    return InterestProfile(
      profileId: json['profileId'] as String? ?? '',
      fullname: json['fullname'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      aboutMe: json['aboutMe'] as String?,
    );
  }
}

class InterestItem {
  const InterestItem({
    this.likeId,
    this.matchId,
    required this.status,
    required this.profile,
  });

  final int? likeId;
  final int? matchId;
  final String status;
  final InterestProfile profile;

  factory InterestItem.fromJson(Map<String, dynamic> json) {
    final profile = Map<String, dynamic>.from(json['profile'] as Map? ?? {});
    return InterestItem(
      likeId: json['likeId'] as int?,
      matchId: json['matchId'] as int?,
      status: json['status'] as String? ?? 'matched',
      profile: InterestProfile.fromJson(profile),
    );
  }
}
