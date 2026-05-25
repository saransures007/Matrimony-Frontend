import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/static_data.dart';

final staticDataRepositoryProvider = Provider<StaticDataRepository>((ref) {
  return StaticDataRepository(ref.watch(apiClientProvider));
});

final staticDataProvider = FutureProvider<StaticData>((ref) {
  return ref.watch(staticDataRepositoryProvider).fetch();
});

class StaticDataRepository {
  const StaticDataRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<StaticData> fetch() async {
    final json = await _apiClient.getJson('/common/static-data');
    final data = json['data'];
    if (data is Map<String, dynamic>) return StaticData.fromJson(data);
    if (data is Map) {
      return StaticData.fromJson(Map<String, dynamic>.from(data));
    }
    return StaticData.fromJson(const {});
  }
}
