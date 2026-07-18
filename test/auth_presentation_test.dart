import 'dart:async';

import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/screens/auth_screens.dart';
import 'package:collectiq_ai/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Sign In is a separate screen with approved header and fields', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-packlox-header')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-sign-in-password-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-email-field')),
      findsNothing,
    );
  });

  testWidgets('S01 welcome renders approved hierarchy', (tester) async {
    await tester.pumpAuthScreen(const AuthWelcomeScreen());

    expect(find.byKey(const ValueKey('auth-welcome-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-welcome-brand-emblem')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('auth-welcome-wordmark')), findsOneWidget);
    expect(find.text('PackLox'), findsOneWidget);
    expect(find.text('Identify. Value. Protect.'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-welcome-hero')), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Explore as Guest'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets('S01 welcome routes to S02 create account email entry', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthWelcomeScreen());

    await tester.tap(find.byKey(const ValueKey('auth-welcome-create-account')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('auth-create-account-email-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-create-account-email-field')),
      findsOneWidget,
    );
  });

  testWidgets('S01 welcome routes to sign in placeholder', (tester) async {
    await tester.pumpAuthScreen(const AuthWelcomeScreen());
    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-welcome-sign-in')),
    );
    await tester.tap(find.byKey(const ValueKey('auth-welcome-sign-in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      findsOneWidget,
    );
  });

  testWidgets('S01 guest action returns to previous route', (tester) async {
    await tester.pumpAuthRoute(route: () => AuthWelcomeScreen.route());

    expect(find.byKey(const ValueKey('auth-welcome-screen')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('auth-welcome-explore-guest')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-welcome-screen')), findsNothing);
    expect(find.byKey(const ValueKey('open-auth-route')), findsOneWidget);
  });

  testWidgets('Settings opens S01 before Sign In without embedding fields', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpAuthScreen(const SettingsScreen());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('settings-auth-email-field')),
      findsNothing,
    );

    await tester.scrollUntilVisible(
      find.text('Sign In').first,
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Sign In').first);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-welcome-screen')), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsNothing);
    expect(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('auth-welcome-sign-in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      findsOneWidget,
    );
  });

  testWidgets('password visibility toggles on Sign In', (tester) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());

    TextField password = tester.widget(
      _textFieldIn(const ValueKey('auth-sign-in-password-field')),
    );
    expect(password.obscureText, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('auth-sign-in-password-visibility')),
    );
    await tester.pump();

    password = tester.widget(
      _textFieldIn(const ValueKey('auth-sign-in-password-field')),
    );
    expect(password.obscureText, isFalse);
  });

  testWidgets('validation remains real and prevents sign-in callback', (
    tester,
  ) async {
    final repository = _InteractiveAuthRepository();
    await tester.pumpAuthRoute(repository: repository);

    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pump();

    expect(find.text('Enter an email address.'), findsOneWidget);
    expect(repository.signInCalls, 0);
  });

  testWidgets('Sign In callback invokes once and loading blocks rapid taps', (
    tester,
  ) async {
    final completer = Completer<AppUser>();
    final repository = _InteractiveAuthRepository(signInCompleter: completer);
    await tester.pumpAuthScreen(
      const AuthSignInScreen(),
      repository: repository,
    );

    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      'collector@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-password-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('auth-sign-in-submit')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(repository.signInCalls, 1);

    completer.complete(_cloudUser('collector@example.com'));
    await tester.pumpAndSettle();
    expect(repository.signInCalls, 1);
  });

  testWidgets('Sign In success returns to previous destination', (
    tester,
  ) async {
    final repository = _InteractiveAuthRepository();
    await tester.pumpAuthRoute(repository: repository);

    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      'collector@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-password-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pumpAndSettle();

    expect(repository.signInCalls, 1);
    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsNothing);
    expect(find.byKey(const ValueKey('open-auth-route')), findsOneWidget);
  });

  testWidgets('human-readable auth error is rendered', (tester) async {
    await tester.pumpAuthScreen(
      const AuthSignInScreen(),
      repository: _InteractiveAuthRepository(
        signInError: const AuthException('Invalid email or password.'),
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      'collector@example.com',
    );
    await tester.enterText(
      find.byKey(const ValueKey('auth-sign-in-password-field')),
      'secret1',
    );
    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
    expect(find.textContaining('Supabase Auth returned'), findsNothing);
  });

  testWidgets('S02 create account email entry renders frozen hierarchy', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthSignUpScreen());

    expect(
      find.byKey(const ValueKey('auth-create-account-email-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-create-account-brand-identity')),
      findsOneWidget,
    );
    expect(find.text('Create your PackLox account'), findsOneWidget);
    expect(
      find.text(
        'Enter your email to start protecting and valuing your collection.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-create-account-email-field')),
      findsOneWidget,
    );
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('you@example.com'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-create-account-continue')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-create-account-sign-in')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-create-account-legal-copy')),
      findsOneWidget,
    );
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-sign-up-password-field')),
      findsNothing,
    );
    expect(find.text('or continue with'), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.textContaining('Facebook'), findsNothing);
  });

  testWidgets('S02 email validation controls Continue availability', (
    tester,
  ) async {
    final repository = _InteractiveAuthRepository();
    await tester.pumpAuthScreen(
      const AuthSignUpScreen(),
      repository: repository,
    );

    TextButton continueButton = tester.widget(
      _textButtonIn(const ValueKey('auth-create-account-continue')),
    );
    expect(continueButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('auth-create-account-email-field')),
      'collector',
    );
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    continueButton = tester.widget(
      _textButtonIn(const ValueKey('auth-create-account-continue')),
    );
    expect(continueButton.onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('auth-create-account-email-field')),
      'collector@example.com',
    );
    await tester.pump();

    expect(find.text('Enter a valid email address.'), findsNothing);
    continueButton = tester.widget(
      _textButtonIn(const ValueKey('auth-create-account-continue')),
    );
    expect(continueButton.onPressed, isNotNull);

    await tester.tap(
      find.byKey(const ValueKey('auth-create-account-continue')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('auth-verify-email-screen')),
      findsOneWidget,
    );
    expect(
      find.text('Enter the code we sent to c***@example.com.'),
      findsOneWidget,
    );
    expect(repository.signUpCalls, 0);
  });

  testWidgets('S02 Continue with valid email navigates to S03', (tester) async {
    await tester.pumpAuthScreen(const AuthSignUpScreen());

    await tester.enterText(
      find.byKey(const ValueKey('auth-create-account-email-field')),
      'hari@example.com',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('auth-create-account-continue')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('auth-verify-email-screen')),
      findsOneWidget,
    );
    expect(find.text('Verify your email'), findsOneWidget);
    expect(
      find.text('Enter the code we sent to h***@example.com.'),
      findsOneWidget,
    );
  });

  testWidgets('S03 hierarchy renders frozen OTP contract', (tester) async {
    await tester.pumpAuthScreen(
      const AuthVerifyEmailScreen(email: 'collector@example.com'),
    );

    expect(
      find.byKey(const ValueKey('auth-verify-email-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-verify-email-brand-identity')),
      findsOneWidget,
    );
    expect(find.text('Verify your email'), findsOneWidget);
    expect(
      find.text('Enter the code we sent to c***@example.com.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-verify-email-otp-field')),
      findsOneWidget,
    );
    expect(find.text('Verification code'), findsOneWidget);
    expect(find.text('6-digit code'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-verify-email-verify')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-verify-email-resend')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-verify-email-change-email')),
      findsOneWidget,
    );
    expect(find.text('This code expires in 10:00.'), findsOneWidget);
    expect(find.text('5 attempts remaining.'), findsOneWidget);
    expect(find.text('Create your password'), findsNothing);
    expect(
      find.byKey(const ValueKey('auth-forgot-password-screen')),
      findsNothing,
    );
  });

  testWidgets('S03 Verify enables only for 6 digits without auto-submit', (
    tester,
  ) async {
    await tester.pumpAuthScreen(
      const AuthVerifyEmailScreen(email: 'collector@example.com'),
    );

    TextButton verifyButton = tester.widget(
      _textButtonIn(const ValueKey('auth-verify-email-verify')),
    );
    expect(verifyButton.onPressed, isNull);

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-verify-email-otp-field')),
      '12345',
    );
    await tester.pump();

    verifyButton = tester.widget(
      _textButtonIn(const ValueKey('auth-verify-email-verify')),
    );
    expect(verifyButton.onPressed, isNull);
    expect(find.textContaining('not correct'), findsNothing);

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-verify-email-otp-field')),
      '123456',
    );
    await tester.pump();

    verifyButton = tester.widget(
      _textButtonIn(const ValueKey('auth-verify-email-verify')),
    );
    expect(verifyButton.onPressed, isNotNull);
    expect(find.textContaining('not correct'), findsNothing);
  });

  testWidgets('S03 Resend code uses 30 second cooldown', (tester) async {
    await tester.pumpAuthScreen(
      const AuthVerifyEmailScreen(email: 'collector@example.com'),
    );

    expect(find.text('Resend code in 30s'), findsOneWidget);
    TextButton resendButton = tester.widget(
      _textButtonIn(const ValueKey('auth-verify-email-resend')),
    );
    expect(resendButton.onPressed, isNull);

    await tester.pump(const Duration(seconds: 30));
    await tester.pump();

    expect(find.text('Resend code'), findsOneWidget);
    resendButton = tester.widget(
      _textButtonIn(const ValueKey('auth-verify-email-resend')),
    );
    expect(resendButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('auth-verify-email-resend')));
    await tester.pump();

    expect(find.text('Resend code in 30s'), findsOneWidget);
    expect(find.text('5 attempts remaining.'), findsOneWidget);
  });

  testWidgets('S03 five attempt lockout requires resend', (tester) async {
    await tester.pumpAuthScreen(
      const AuthVerifyEmailScreen(email: 'collector@example.com'),
    );

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-verify-email-otp-field')),
      '123456',
    );
    await tester.pump();

    for (var attempt = 0; attempt < 5; attempt += 1) {
      await tester.tap(find.byKey(const ValueKey('auth-verify-email-verify')));
      await tester.pump();
    }

    expect(find.text('Too many attempts. Request a new code.'), findsOneWidget);
    expect(find.text('Request a new code to try again.'), findsOneWidget);

    TextButton verifyButton = tester.widget(
      _textButtonIn(const ValueKey('auth-verify-email-verify')),
    );
    expect(verifyButton.onPressed, isNull);

    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-verify-email-resend')));
    await tester.pump();

    expect(find.text('Too many attempts. Request a new code.'), findsNothing);
    expect(find.text('5 attempts remaining.'), findsOneWidget);
    verifyButton = tester.widget(
      _textButtonIn(const ValueKey('auth-verify-email-verify')),
    );
    expect(verifyButton.onPressed, isNull);
  });

  testWidgets('S03 Change email returns to S02', (tester) async {
    await tester.pumpAuthScreen(const AuthSignUpScreen());

    await tester.enterText(
      find.byKey(const ValueKey('auth-create-account-email-field')),
      'collector@example.com',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('auth-create-account-continue')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('auth-verify-email-screen')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('auth-verify-email-change-email')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('auth-create-account-email-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-verify-email-screen')),
      findsNothing,
    );
  });

  testWidgets('S02 Sign In bridge opens the sign-in route shell', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());

    await tester.ensureVisible(find.byKey(const ValueKey('auth-open-sign-up')));
    await tester.tap(find.byKey(const ValueKey('auth-open-sign-up')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('auth-create-account-email-screen')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-create-account-sign-in')),
    );
    await tester.tap(find.byKey(const ValueKey('auth-create-account-sign-in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
  });

  testWidgets(
    'Forgot Password route invokes recovery once and explains web flow',
    (tester) async {
      final repository = _InteractiveAuthRepository();
      await tester.pumpAuthScreen(
        const AuthForgotPasswordScreen(),
        repository: repository,
      );

      await tester.enterText(
        find.byKey(const ValueKey('auth-forgot-email-field')),
        'reset@example.com',
      );
      await tester.tap(find.byKey(const ValueKey('auth-forgot-submit')));
      await tester.pumpAndSettle();

      expect(repository.passwordResetCalls, 1);
      expect(repository.lastPasswordResetEmail, 'reset@example.com');
      expect(
        find.byKey(const ValueKey('auth-recovery-web-handoff')),
        findsOneWidget,
      );
      expect(find.textContaining('secure web link'), findsOneWidget);
    },
  );

  testWidgets('Forgot Password rate limit and errors stay human-readable', (
    tester,
  ) async {
    final rateLimitedRepository = _InteractiveAuthRepository(
      passwordResetError: const SupabasePasswordResetRateLimitedException(
        cooldown: Duration(minutes: 5),
        cooldownSource: 'fallback',
      ),
    );
    await tester.pumpAuthScreen(
      const AuthForgotPasswordScreen(),
      repository: rateLimitedRepository,
    );

    await tester.enterText(
      find.byKey(const ValueKey('auth-forgot-email-field')),
      'reset@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('auth-forgot-submit')));
    await tester.pumpAndSettle();

    expect(rateLimitedRepository.passwordResetCalls, 1);
    expect(find.text(AuthMessages.passwordResetRateLimited), findsOneWidget);

    final failingRepository = _InteractiveAuthRepository(
      passwordResetError: const AuthException(
        'Unable to reach Supabase. Check your internet connection.',
      ),
    );
    await tester.pumpAuthScreen(
      const AuthForgotPasswordScreen(),
      repository: failingRepository,
    );

    await tester.enterText(
      find.byKey(const ValueKey('auth-forgot-email-field')),
      'reset@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('auth-forgot-submit')));
    await tester.pumpAndSettle();

    expect(failingRepository.passwordResetCalls, 1);
    expect(
      find.text('Unable to reach Supabase. Check your internet connection.'),
      findsOneWidget,
    );
  });

  testWidgets('Guest return remains available without auth guard', (
    tester,
  ) async {
    await tester.pumpAuthRoute();

    expect(find.byKey(const ValueKey('auth-continue-guest')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-guest-access-note')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-continue-guest')),
    );
    await tester.tap(find.byKey(const ValueKey('auth-continue-guest')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsNothing);
  });

  testWidgets('Settings signed-in summary and sign-out remain real', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _InteractiveAuthRepository(
      initialUser: _cloudUser('collector@example.com'),
    );
    await tester.pumpAuthScreen(const SettingsScreen(), repository: repository);
    await tester.pumpAndSettle();

    expect(find.text('collector@example.com'), findsWidgets);
    expect(
      find.byKey(const ValueKey('settings-auth-email-field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('settings-auth-sign-in-button')),
      findsNothing,
    );
    expect(find.text('Sign Out'), findsOneWidget);

    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
  });

  test('AuthController can rebuild without replacing session state', () async {
    final repository = _InteractiveAuthRepository(
      initialUser: _cloudUser('collector@example.com'),
    );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).loadCurrentUser();
    expect(container.read(authControllerProvider).isSignedIn, isTrue);

    container.invalidate(authControllerProvider);
    await container.read(authControllerProvider.notifier).loadCurrentUser();

    final state = container.read(authControllerProvider);
    expect(state.isSignedIn, isTrue);
    expect(state.user?.email, 'collector@example.com');
    expect(repository.currentUserCalls, greaterThanOrEqualTo(2));
  });

  testWidgets('auth screens fit 320px and large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpAuthScreen(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
        child: const AuthSignInScreen(),
      ),
    );

    expect(find.byKey(const ValueKey('auth-scroll-view')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dark and light themes render auth presentation', (tester) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());
    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);

    await tester.pumpAuthScreen(
      const AuthSignInScreen(),
      themeMode: ThemeMode.light,
    );
    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
  });
}

extension on WidgetTester {
  Future<void> pumpAuthScreen(
    Widget child, {
    AuthRepository? repository,
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            repository ?? _InteractiveAuthRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: Scaffold(body: child),
        ),
      ),
    );
    await pump();
  }

  Future<void> pumpAuthRoute({
    AuthRepository? repository,
    ThemeMode themeMode = ThemeMode.dark,
    Route<void> Function()? route,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            repository ?? _InteractiveAuthRepository(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const ValueKey('open-auth-route'),
                  onPressed: () => Navigator.of(
                    context,
                  ).push(route?.call() ?? AuthSignInScreen.route()),
                  child: const Text('Open auth'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await pump();
    await tap(find.byKey(const ValueKey('open-auth-route')));
    await pumpAndSettle();
  }
}

Finder _textFieldIn(Key key) {
  return find.descendant(of: find.byKey(key), matching: find.byType(TextField));
}

Finder _textButtonIn(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(TextButton),
  );
}

class _InteractiveAuthRepository implements AuthRepository {
  _InteractiveAuthRepository({
    AppUser? initialUser,
    this.signInError,
    this.passwordResetError,
    this.signInCompleter,
  }) : _user = initialUser;

  AppUser? _user;
  final Object? signInError;
  final Object? passwordResetError;
  final Completer<AppUser>? signInCompleter;
  var currentUserCalls = 0;
  var signInCalls = 0;
  var signUpCalls = 0;
  var resendCalls = 0;
  var passwordResetCalls = 0;
  var signOutCalls = 0;
  String? lastResendEmail;
  String? lastPasswordResetEmail;

  @override
  Future<AppUser?> currentUser() async {
    currentUserCalls += 1;
    return _user;
  }

  @override
  Future<AppUser> signIn() => signInAnonymously();

  @override
  Future<AppUser> signInAnonymously() async {
    _user = const AppUser(
      id: 'local-user',
      displayName: 'Local Collector',
      email: null,
      isAnonymous: true,
      isLocalOnly: true,
      provider: AuthProviderType.localAnonymous,
    );
    return _user!;
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    if (signInError != null) {
      throw signInError!;
    }
    final completer = signInCompleter;
    if (completer != null) {
      _user = await completer.future;
      return _user!;
    }
    _user = _cloudUser(email);
    return _user!;
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    _user = _cloudUser(email);
    return _user!;
  }

  @override
  Future<void> resendEmailConfirmation({required String email}) async {
    resendCalls += 1;
    lastResendEmail = email;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    passwordResetCalls += 1;
    lastPasswordResetEmail = email;
    if (passwordResetError != null) {
      throw passwordResetError!;
    }
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw const AuthException('Google sign-in is not enabled.');
  }

  @override
  Future<AppUser> signInWithApple() {
    throw const AuthException('Apple sign-in is not enabled.');
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    _user = null;
  }
}

AppUser _cloudUser(String email) {
  return AppUser(
    id: 'cloud-user',
    displayName: email,
    email: email,
    provider: AuthProviderType.emailPassword,
  );
}
