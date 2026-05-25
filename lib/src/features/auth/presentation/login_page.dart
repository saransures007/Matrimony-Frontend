import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import 'auth_controller.dart';
import 'register_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/language_switcher.dart';

final loginMethodProvider = StateProvider<LoginMethod>(
  (ref) => LoginMethod.password,
);

enum LoginMethod { password, otp }

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.initialError});

  final String? initialError;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _showOtpFields = false;
  String? _otpError;
  bool _otpLoading = false;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      _currentPage = (_currentPage + 1) % 3;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      _startAutoSlide();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final n in _otpFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String _getOtp() => _otpControllers.map((c) => c.text).join();

  Future<void> _submitPasswordLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(_identifierController.text, _passwordController.text);
  }

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(
        () => _otpError = ref.read(localizationsProvider).enterValidPhone,
      );
      return;
    }

    setState(() {
      _otpLoading = true;
      _otpError = null;
    });

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.requestLoginOtp(phone);

    if (mounted) {
      setState(() {
        _otpLoading = false;
        if (result.success) {
          _showOtpFields = true;
        } else {
          _otpError = result.message;
        }
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _getOtp();
    if (otp.length != 6) {
      setState(
        () => _otpError = ref.read(localizationsProvider).enterCompleteOtp,
      );
      return;
    }

    setState(() {
      _otpLoading = true;
      _otpError = null;
    });

    final phone = _phoneController.text.trim();
    await ref.read(authControllerProvider.notifier).loginWithOtp(phone, otp);

    if (mounted) {
      setState(() => _otpLoading = false);
    }
  }

  void _switchToPasswordLogin() {
    ref.read(loginMethodProvider.notifier).state = LoginMethod.password;
    setState(() {
      _showOtpFields = false;
      _otpError = null;
      _otpLoading = false;
      for (final c in _otpControllers) {
        c.clear();
      }
    });
  }

  void _switchToOtpLogin() {
    ref.read(loginMethodProvider.notifier).state = LoginMethod.otp;
    setState(() {
      _showOtpFields = false;
      _otpError = null;
      _otpLoading = false;
      for (final c in _otpControllers) {
        c.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final loginMethod = ref.watch(loginMethodProvider);
    final loc = ref.watch(localizationsProvider);
    final error = auth.hasError ? auth.error.toString() : widget.initialError;
    final isLoading = auth.isLoading || _otpLoading;

    return Scaffold(
      body: Column(
        children: [
          // ✅ TOP: Image Slider 70% of screen (premium feel)
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/login/1.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/login/2.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/login/3.png'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),

                // 🌍 Language switcher at top right corner ON TOP OF IMAGE
                SafeArea(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, top: 14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Consumer(
                          builder: (context, ref, child) {
                            return LanguageSwitcher(isDark: true);
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Gradient Overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                ),
                // Page Indicator
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),

          // ✅ BOTTOM: Login Form 30% of screen
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // Password Login Form
                      if (loginMethod == LoginMethod.password) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _identifierController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: loc.emailPhoneUsername,
                                  prefixIcon: const Icon(Icons.person_outline),
                                  isDense: true,
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? loc.enterLoginId
                                    : null,
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  labelText: loc.password,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  isDense: true,
                                ),
                                validator: (value) =>
                                    value == null || value.length < 6
                                    ? loc.passwordMinLength
                                    : null,
                                onFieldSubmitted: (_) => _submitPasswordLogin(),
                              ),
                            ],
                          ),
                        ),
                        if (error != null) ...[
                          const SizedBox(height: 8),
                          _ErrorBanner(error),
                        ],
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: isLoading ? null : _submitPasswordLogin,
                          icon: isLoading
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login, size: 18),
                          label: Text(loc.signIn),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                        ),
                      ],

                      // OTP Login Form
                      if (loginMethod == LoginMethod.otp) ...[
                        // Phone number field
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          enabled: !isLoading,
                          decoration: InputDecoration(
                            labelText: loc.mobileNumber,
                            hintText: loc.enterMobileNumber,
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            isDense: true,
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
                        const SizedBox(height: 10),

                        // OTP fields (shown after OTP is sent)
                        if (_showOtpFields) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(6, (index) {
                              return Container(
                                width: 40,
                                height: 48,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                child: TextFormField(
                                  controller: _otpControllers[index],
                                  focusNode: _otpFocusNodes[index],
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  enabled: !isLoading,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 5) {
                                      _otpFocusNodes[index + 1].requestFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      _otpFocusNodes[index - 1].requestFocus();
                                    }
                                  },
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Error message
                        if (_otpError != null) ...[
                          _ErrorBanner(_otpError!),
                          const SizedBox(height: 12),
                        ],

                        // Buttons
                        if (!_showOtpFields)
                          FilledButton.icon(
                            onPressed: isLoading ? null : _requestOtp,
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sms, size: 18),
                            label: Text(loc.sendOtp),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
                          )
                        else
                          FilledButton.icon(
                            onPressed: isLoading ? null : _verifyOtp,
                            icon: isLoading
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.check_circle, size: 18),
                            label: Text(loc.verifyLogin),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(44),
                            ),
                          ),
                      ],

                      const SizedBox(height: 6),

                      // ✅ Switch login method text button at bottom
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                if (loginMethod == LoginMethod.password) {
                                  _switchToOtpLogin();
                                } else {
                                  _switchToPasswordLogin();
                                }
                              },
                        child: Text(
                          loginMethod == LoginMethod.password
                              ? loc.loginWithOtpInstead
                              : loc.loginWithPasswordInstead,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      OutlinedButton.icon(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const RegisterPage(),
                                ),
                              ),
                        icon: const Icon(
                          Icons.person_add_alt_1_outlined,
                          size: 18,
                        ),
                        label: Text(loc.createAccount),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          message,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
