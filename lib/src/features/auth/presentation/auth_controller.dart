import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/registration_payload.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthSession?> {
  late final AuthRepository _repo;

  @override
  Future<AuthSession?> build() async {
    _repo = ref.watch(authRepositoryProvider);
    return _repo.restore();
  }

  Future<void> login(String identifier, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.loginWithPassword(identifier: identifier, password: password),
    );
  }

  Future<void> loginWithOtp(String phone, String otp) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.loginWithOtp(phone: phone, otp: otp),
    );
  }

  Future<void> register(RegistrationPayload payload) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.register(payload));
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}
