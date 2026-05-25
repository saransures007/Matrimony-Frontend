import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:matrimony_flutter/src/app.dart';
import 'package:matrimony_flutter/src/features/auth/domain/auth_session.dart';
import 'package:matrimony_flutter/src/features/auth/presentation/auth_controller.dart';

class _FakeAuthController extends AuthController {
  @override
  Future<AuthSession?> build() async => null;
}

void main() {
  testWidgets('renders login screen by default', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
        ],
        child: const MatrimonyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SKS Matrimony'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
