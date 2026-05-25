import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_store.dart';
import '../domain/auth_session.dart';
import '../domain/registration_payload.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStoreProvider),
  );
});

class AuthRepository {
  const AuthRepository(this._apiClient, this._tokenStore);

  final ApiClient _apiClient;
  final TokenStore _tokenStore;

  Future<AuthSession?> restore() async {
    final token = await _tokenStore.readToken();
    if (token == null || token.isEmpty) return null;
    // Could validate token with server here if needed
    return AuthSession(token: token);
  }

  Future<AuthSession> loginWithPassword({
    required String identifier,
    required String password,
  }) async {
    final response = await _apiClient.postJson('/auth/login/password', {
      'identifier': identifier,
      'password': password,
    });
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    await _tokenStore.saveToken(token);
    return AuthSession(token: token);
  }

  Future<AuthSession> register(RegistrationPayload payload) async {
    final response = await _apiClient.postJson('/auth/register', payload.toApiJson());
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    await _tokenStore.saveToken(token);
    return AuthSession(token: token);
  }

  Future<AuthSession> loginWithOtp({
    required String phone,
    required String otp,
  }) async {
    final response = await _apiClient.postJson('/auth/otp/verify', {
      'phone': phone,
      'otp': otp,
    });
    final data = response['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    await _tokenStore.saveToken(token);
    return AuthSession(token: token);
  }

  Future<void> logout() async {
    await _tokenStore.clear();
  }

  /// Checks if email or phone number is available for registration
  Future<AvailabilityResult> checkAvailability({
    String? email,
    String? phone,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (email != null && email.isNotEmpty) queryParams['email'] = email;
      if (phone != null && phone.isNotEmpty) queryParams['phone'] = phone;

      if (queryParams.isEmpty) {
        return AvailabilityResult(
          email: null,
          phone: null,
        );
      }

      final response = await _apiClient.getJson(
        '/auth/check-availability?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}',
      );

      final data = response['data'] as Map<String, dynamic>?;

      return AvailabilityResult(
        email: data?['email']?['available'] as bool?,
        phone: data?['phone']?['available'] as bool?,
      );
    } catch (e) {
      // Return available = false on error (safer for UX)
      return AvailabilityResult(
        email: null,
        phone: null,
        error: e.toString(),
      );
    }
  }

  /// Request OTP for login
  Future<OtpSendResult> requestLoginOtp(String phone) async {
    try {
      final response = await _apiClient.postJson('/auth/otp/request', {
        'phone': phone,
      });
      return OtpSendResult(
        success: true,
        message: response['message'] as String? ?? 'OTP sent successfully',
      );
    } catch (e) {
      return OtpSendResult(
        success: false,
        message: e.toString(),
      );
    }
  }

  /// Verify OTP for login
  Future<OtpVerifyResult> verifyLoginOtp(String phone, String otp) async {
    try {
      final response = await _apiClient.postJson('/auth/otp/verify', {
        'phone': phone,
        'otp': otp,
      });
      final data = response['data'] as Map<String, dynamic>?;
      return OtpVerifyResult(
        success: true,
        token: data?['token'] as String?,
        accountId: data?['accountId'] as String?,
        message: response['message'] as String? ?? 'Login successful',
      );
    } catch (e) {
      return OtpVerifyResult(
        success: false,
        message: e.toString(),
      );
    }
  }
}

class AvailabilityResult {
  final bool? email;
  final bool? phone;
  final String? error;

  AvailabilityResult({
    this.email,
    this.phone,
    this.error,
  });

  bool get hasError => error != null;

  bool? get emailAvailability => email;
  bool? get phoneAvailability => phone;
}

class OtpSendResult {
  final bool success;
  final String message;

  OtpSendResult({required this.success, required this.message});
}

class OtpVerifyResult {
  final bool success;
  final String? token;
  final String? accountId;
  final String message;

  OtpVerifyResult({
    required this.success,
    this.token,
    this.accountId,
    required this.message,
  });
}
