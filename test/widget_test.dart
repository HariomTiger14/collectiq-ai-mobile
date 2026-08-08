import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PackLox launches to the signed-out welcome screen', (
    tester,
  ) async {
    await tester.pumpPackLoxApp();

    expect(find.byKey(const ValueKey('auth-welcome-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-welcome-hero')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-welcome-create-account')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('auth-welcome-sign-in')), findsOneWidget);
    expect(find.text('Identify. Value. Protect.'), findsOneWidget);
    expect(find.byKey(const ValueKey('app-shell')), findsNothing);
  });

  testWidgets('welcome sign in action opens the sign in screen', (
    tester,
  ) async {
    await tester.pumpPackLoxApp();

    await tester.tap(find.byKey(const ValueKey('auth-welcome-sign-in')));
    await tester.pumpTabSwitch();

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-sign-in-password-field')),
      findsOneWidget,
    );
  });

  testWidgets('welcome create account action opens account creation', (
    tester,
  ) async {
    await tester.pumpPackLoxApp();

    await tester.tap(find.byKey(const ValueKey('auth-welcome-create-account')));
    await tester.pumpTabSwitch();

    expect(
      find.byKey(const ValueKey('auth-create-account-email-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-create-account-email-field')),
      findsOneWidget,
    );
  });

  testWidgets('signed-in completed onboarding launches to the Home shell', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
    await tester.pumpPackLoxApp(
      authRepository: _SignedInAuthRepository(),
    );

    expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('shell-destination-home')),
      findsOneWidget,
    );
    expect(find.text('Your collection is waiting'), findsOneWidget);
  });

  testWidgets('bottom navigation exposes the current five destinations', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
    await tester.pumpPackLoxApp(
      authRepository: _SignedInAuthRepository(),
    );

    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-scan')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-portfolio')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-search')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-settings')), findsOneWidget);
  });

  testWidgets('bottom navigation opens scan portfolio search and settings', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
    await tester.pumpPackLoxApp(
      authRepository: _SignedInAuthRepository(),
    );

    await tester.tap(find.byKey(const ValueKey('nav-scan')));
    await tester.pumpTabSwitch();
    expect(
      find.byKey(const ValueKey('shell-destination-scan')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-hub-capture-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('nav-portfolio')));
    await tester.pumpTabSwitch();
    expect(
      find.byKey(const ValueKey('shell-destination-portfolio')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('nav-search')));
    await tester.pumpTabSwitch();
    expect(
      find.byKey(const ValueKey('shell-destination-search')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await tester.pumpTabSwitch();
    expect(
      find.byKey(const ValueKey('shell-destination-settings')),
      findsOneWidget,
    );
    expect(find.text('Account'), findsWidgets);
    expect(find.text('Price Alerts'), findsOneWidget);
  });

  testWidgets('home primary scan action opens the scan hub', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed_v1': true});
    await tester.pumpPackLoxApp(
      authRepository: _SignedInAuthRepository(),
    );

    await tester.ensureVisible(find.byKey(const ValueKey('home-primary-scan')));
    await tester.tap(find.byKey(const ValueKey('home-primary-scan')));
    await tester.pumpTabSwitch();

    expect(
      find.byKey(const ValueKey('shell-destination-scan')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('scan-hub-capture-button')),
      findsOneWidget,
    );
  });
}

extension on WidgetTester {
  Future<void> pumpPackLoxApp({
    AuthRepository? authRepository,
  }) async {
    await pumpWidget(
      authRepository == null
          ? const ProviderScope(child: CollectIqApp())
          : ProviderScope(
              overrides: [
                authRepositoryProvider.overrideWithValue(authRepository),
              ],
              child: const CollectIqApp(),
            ),
    );
    await pump();
    await pump(const Duration(milliseconds: 120));
  }

  Future<void> pumpTabSwitch() async {
    await pump();
    await pump(const Duration(milliseconds: 240));
  }
}

class _SignedInAuthRepository implements AuthRepository {
  static const _user = AppUser(
    id: 'test-user',
    displayName: 'Test Collector',
    email: 'collector@example.com',
    provider: AuthProviderType.emailPassword,
  );

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<void> resendEmailConfirmation({required String email}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<AppUser> signIn() async => _user;

  @override
  Future<AppUser> signInAnonymously() async => _user;

  @override
  Future<AppUser> signInWithApple() async => _user;

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async => _user;

  @override
  Future<AppUser> signInWithGoogle() async => _user;

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async => _user;
}
