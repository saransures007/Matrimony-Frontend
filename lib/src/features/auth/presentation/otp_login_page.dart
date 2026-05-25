import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'auth_controller.dart';
import '../../../l10n/app_localizations.dart';

// NOTE: Navigation after OTP login is handled by AuthGate in app.dart.
// When authControllerProvider state updates to a valid session,
// AuthGate automatically swaps LoginPage for HomeShell.

final otpLoginStateProvider =
    StateNotifierProvider<OtpLoginNotifier, OtpLoginState>(
      (ref) => OtpLoginNotifier(ref.watch(authRepositoryProvider)),
    );

class OtpLoginNotifier extends StateNotifier<OtpLoginState> {
  final AuthRepository _repo;

  OtpLoginNotifier(this._repo) : super(const OtpLoginState());

  Future<void> requestOtp(String phone) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.requestLoginOtp(phone);
      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          otpSent: true,
          message: result.message,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repo.verifyLoginOtp(phone, otp);
      if (result.success) {
        state = state.copyWith(
          isLoading: false,
          success: true,
          message: result.message,
        );
      } else {
        state = state.copyWith(isLoading: false, error: result.message);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() {
    state = const OtpLoginState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class OtpLoginState {
  final bool isLoading;
  final bool otpSent;
  final bool success;
  final String? error;
  final String? message;

  const OtpLoginState({
    this.isLoading = false,
    this.otpSent = false,
    this.success = false,
    this.error,
    this.message,
  });

  OtpLoginState copyWith({
    bool? isLoading,
    bool? otpSent,
    bool? success,
    String? error,
    String? message,
  }) {
    return OtpLoginState(
      isLoading: isLoading ?? this.isLoading,
      otpSent: otpSent ?? this.otpSent,
      success: success ?? this.success,
      error: error ?? this.error,
      message: message ?? this.message,
    );
  }
}

class OtpLoginPage extends ConsumerStatefulWidget {
  const OtpLoginPage({super.key});

  @override
  ConsumerState<OtpLoginPage> createState() => _OtpLoginPageState();
}

class _OtpLoginPageState extends ConsumerState<OtpLoginPage> {
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (index) => TextEditingController());
  final _formKey = GlobalKey<FormState>();
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());
  bool _showOtpField = false;

  @override
  void dispose() {
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpLoginStateProvider);
    final loc = ref.watch(localizationsProvider);

    // Auth navigation is handled by AuthGate in app.dart
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.otpLogin),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.security, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              loc.secureOtpLogin,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loc.otpLoginSubtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Phone number field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    enabled: !otpState.isLoading,
                    decoration: InputDecoration(
                      labelText: loc.phoneNumber,
                      hintText: loc.enterMobileNumber,
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return loc.phoneRequired;
                      }
                      if (value.trim().length != 10) {
                        return loc.enterValidPhone;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // OTP field (shown after OTP is sent)
                  if (_showOtpField) ...[
                    Text(
                      loc.enterOtpSent(_phoneController.text.trim()),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        return Container(
                          width: 48,
                          height: 56,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: TextFormField(
                            controller: _otpControllers[index],
                            focusNode: _focusNodes[index],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            enabled: !otpState.isLoading,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty && index < 5) {
                                _focusNodes[index + 1].requestFocus();
                              } else if (value.isEmpty && index > 0) {
                                _focusNodes[index - 1].requestFocus();
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Error message
                  if (otpState.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              otpState.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => ref
                                .read(otpLoginStateProvider.notifier)
                                .clearError(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: otpState.isLoading
                          ? null
                          : _showOtpField
                          ? _verifyOtp
                          : _requestOtp,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: otpState.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_showOtpField ? loc.verifyLogin : loc.sendOtp),
                    ),
                  ),

                  if (_showOtpField) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: otpState.isLoading
                          ? null
                          : () {
                              setState(() {
                                _showOtpField = false;
                                for (final c in _otpControllers) {
                                  c.clear();
                                }
                              });
                              ref.read(otpLoginStateProvider.notifier).reset();
                            },
                      child: Text(loc.changePhoneNumber),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    setState(() => _showOtpField = true);

    await ref.read(otpLoginStateProvider.notifier).requestOtp(phone);
  }

  Future<void> _verifyOtp() async {
    final otp = _getOtp();
    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ref.read(localizationsProvider).enterCompleteOtp),
        ),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    // First verify OTP via notifier for loading/error UI state
    await ref.read(otpLoginStateProvider.notifier).verifyOtp(phone, otp);

    final otpState = ref.read(otpLoginStateProvider);
    if (otpState.success) {
      // Save token and update auth session — this triggers navigation to HomeShell
      await ref.read(authControllerProvider.notifier).loginWithOtp(phone, otp);
    }
  }
}
