import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/match_profile.dart';

final matchesRepositoryProvider = Provider<MatchesRepository>((ref) {
  return MatchesRepository(ref.watch(apiClientProvider));
});

final matchesProvider = FutureProvider<List<MatchProfile>>((ref) {
  return ref.watch(matchesRepositoryProvider).fetchNextProfiles();
});

final profileDetailsProvider = FutureProvider.family<MatchProfile, String>((
  ref,
  profileId,
) {
  return ref.watch(matchesRepositoryProvider).fetchProfileDetails(profileId);
});

class SwipeResult {
  const SwipeResult({
    required this.status,
    required this.matched,
    this.matchId,
    this.likeId,
  });

  final String status;
  final bool matched;
  final String? matchId;
  final int? likeId;

  factory SwipeResult.fromJson(Map<String, dynamic> json) {
    return SwipeResult(
      status: json['status'] as String? ?? 'pending',
      matched: json['matched'] as bool? ?? false,
      matchId: json['matchId']?.toString(),
      likeId: json['likeId'] as int?,
    );
  }
}

class MatchesRepository {
  const MatchesRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<MatchProfile>> fetchNextProfiles({String? cursor}) async {
    final response = await _apiClient.getJson(
      cursor == null ? '/swipes/next' : '/swipes/next?cursor=$cursor',
    );
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => MatchProfile.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<SwipeResult> swipe({
    required String targetProfileId,
    required bool liked,
  }) async {
    final response = await _apiClient.postJson('/swipes', {
      'targetProfileId': targetProfileId,
      'action': liked ? 'like' : 'reject',
    });

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return SwipeResult.fromJson(data);
    }
    if (data is Map) {
      return SwipeResult.fromJson(Map<String, dynamic>.from(data));
    }
    return const SwipeResult(status: 'unknown', matched: false);
  }

  Future<MatchProfile> fetchProfileDetails(String profileId) async {
    final response = await _apiClient.getJson('/swipes/profiles/$profileId');
    return MatchProfile.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}
