import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/interest_item.dart';

final interestsRepositoryProvider = Provider<InterestsRepository>((ref) {
  return InterestsRepository(ref.watch(apiClientProvider));
});

final receivedInterestsProvider = FutureProvider<List<InterestItem>>((ref) {
  return ref.watch(interestsRepositoryProvider).received();
});

final sentInterestsProvider = FutureProvider<List<InterestItem>>((ref) {
  return ref.watch(interestsRepositoryProvider).sent();
});

final interestMatchesProvider = FutureProvider<List<InterestItem>>((ref) {
  return ref.watch(interestsRepositoryProvider).matches();
});

class InterestsRepository {
  const InterestsRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<InterestItem>> received() => _list('/interests/received');
  Future<List<InterestItem>> sent() => _list('/interests/sent');
  Future<List<InterestItem>> matches() => _list('/interests/matches');

  Future<void> accept(int likeId) async {
    await _apiClient.postJson('/interests/$likeId/accept', const {});
  }

  Future<void> reject(int likeId) async {
    await _apiClient.postJson('/interests/$likeId/reject', const {});
  }

  Future<List<InterestItem>> _list(String path) async {
    final response = await _apiClient.getJson(path);
    final data = response['data'];
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((item) => InterestItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
