import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_store.dart';
import 'api_exception.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStore = ref.watch(tokenStoreProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await tokenStore.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(dioProvider));
});

class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getJson(String path) async {
    try {
      final response = await _dio.get<Object?>(path);
      return _asJson(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Object?>(path, data: body);
      return _asJson(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.put<Object?>(path, data: body);
      return _asJson(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.patch<Object?>(path, data: body);
      return _asJson(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<Map<String, dynamic>> deleteJson(String path) async {
    try {
      final response = await _dio.delete<Object?>(path);
      return _asJson(response.data);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Map<String, dynamic> _asJson(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('Unexpected API response format');
  }

  ApiException _mapError(DioException error) {
    final data = error.response?.data;
    final statusCode = error.response?.statusCode;
    if (data is Map && data['message'] != null) {
      return ApiException(data['message'].toString(), statusCode: statusCode);
    }
    if (statusCode == 401 || statusCode == 403) {
      return ApiException(
        'The server rejected this request. Check the API base URL and your login session.',
        statusCode: statusCode,
      );
    }
    if (statusCode != null) {
      return ApiException(
        'Request failed with HTTP $statusCode.',
        statusCode: statusCode,
      );
    }
    return ApiException(
      'Could not reach the backend. Make sure the server is running and API_BASE_URL points to it.',
      statusCode: statusCode,
    );
  }
}
