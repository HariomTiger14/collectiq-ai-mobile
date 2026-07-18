import 'dart:async';

import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_backend_repository.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/guest_mode_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_backend_contract_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/guest_mode_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/screens/auth_screens.dart';
import 'package:collectiq_ai/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_auth_backend_repository.dart';

void main() {
  testWidgets('S05 hierarchy renders frozen sign in contract', (tester) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-sign-in-brand-identity')),
      findsOneWidget,
    );
    expect(find.text('Welcome back'), findsOneWidget);
    expect(
      find.text('Sign in to continue protecting your collection.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-sign-in-email-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-sign-in-password-field')),
      findsOneWidget,
    );
    expect(find.text('Email address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-sign-in-submit')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-forgot-password-link')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-sign-in-create-account-bridge')),
      findsOneWidget,
    );
    expect(find.text('New to PackLox?'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-sign-in-provider-block')),
      findsNothing,
    );
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Facebook'), findsNothing);
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

  testWidgets(
    'S05 Sign In disabled for empty invalid email or empty password',
    (tester) async {
      final repository = _InteractiveAuthRepository();
      await tester.pumpAuthScreen(
        const AuthSignInScreen(),
        repository: repository,
      );

      TextButton signInButton = tester.widget(
        _textButtonIn(const ValueKey('auth-sign-in-submit')),
      );
      expect(signInButton.onPressed, isNull);

      await tester.enterText(
        _textFieldIn(const ValueKey('auth-sign-in-email-field')),
        'not-an-email',
      );
      await tester.enterText(
        _textFieldIn(const ValueKey('auth-sign-in-password-field')),
        'password',
      );
      await tester.pump();

      signInButton = tester.widget(
        _textButtonIn(const ValueKey('auth-sign-in-submit')),
      );
      expect(signInButton.onPressed, isNull);

      await tester.enterText(
        _textFieldIn(const ValueKey('auth-sign-in-email-field')),
        'collector@example.com',
      );
      await tester.enterText(
        _textFieldIn(const ValueKey('auth-sign-in-password-field')),
        '',
      );
      await tester.pump();

      signInButton = tester.widget(
        _textButtonIn(const ValueKey('auth-sign-in-submit')),
      );
      expect(signInButton.onPressed, isNull);
      expect(repository.signInCalls, 0);
    },
  );

  testWidgets('S05 Sign In calls backend contract with email and password', (
    tester,
  ) async {
    final backendRepository = InMemoryAuthBackendRepository(
      accounts: const [
        InMemoryAuthAccount(
          email: 'collector@example.com',
          password: 'correct horse battery staple',
        ),
      ],
    );
    await tester.pumpAuthScreen(
      const AuthSignInScreen(),
      backendRepository: backendRepository,
    );

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-sign-in-email-field')),
      'Collector@Example.com ',
    );
    await tester.enterText(
      _textFieldIn(const ValueKey('auth-sign-in-password-field')),
      'correct horse battery staple',
    );
    await tester.pump();

    final signInButton = tester.widget<TextButton>(
      _textButtonIn(const ValueKey('auth-sign-in-submit')),
    );
    expect(signInButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pumpAndSettle();

    expect(backendRepository.signInCalls, 1);
    expect(backendRepository.lastSignInEmail, 'collector@example.com');
    expect(
      backendRepository.lastSignInPassword,
      'correct horse battery staple',
    );
    expect(find.text('Email or password is not correct.'), findsNothing);
  });

  testWidgets('S05 successful sign-in updates app authenticated state', (
    tester,
  ) async {
    final backendRepository = InMemoryAuthBackendRepository(
      accounts: const [
        InMemoryAuthAccount(
          email: 'collector@example.com',
          password: 'correct horse battery staple',
        ),
      ],
    );
    final container = await tester.pumpAuthScreenWithContainer(
      const AuthSignInScreen(),
      backendRepository: backendRepository,
    );

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-sign-in-email-field')),
      'collector@example.com',
    );
    await tester.enterText(
      _textFieldIn(const ValueKey('auth-sign-in-password-field')),
      'correct horse battery staple',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pumpAndSettle();

    expect(
      container.read(authBackendContractControllerProvider).status,
      AuthBackendContractStatus.signedIn,
    );
    expect(container.read(authControllerProvider).isSignedIn, isTrue);
  });

  testWidgets(
    'S05 invalid credentials use neutral copy without account disclosure',
    (tester) async {
      final backendRepository = InMemoryAuthBackendRepository();
      await tester.pumpAuthScreen(
        const AuthSignInScreen(),
        backendRepository: backendRepository,
      );

      await tester.enterText(
        _textFieldIn(const ValueKey('auth-sign-in-email-field')),
        'missing@example.com',
      );
      await tester.enterText(
        _textFieldIn(const ValueKey('auth-sign-in-password-field')),
        'wrong password',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
      await tester.pumpAndSettle();

      expect(backendRepository.signInCalls, 1);
      expect(find.text('Email or password is not correct.'), findsOneWidget);
      expect(find.textContaining('not found'), findsNothing);
      expect(find.textContaining('sign up first'), findsNothing);
    },
  );

  testWidgets('S05 loading state disables Sign In CTA', (tester) async {
    final signInGate = Completer<void>();
    final backendRepository = InMemoryAuthBackendRepository(
      accounts: const [
        InMemoryAuthAccount(
          email: 'collector@example.com',
          password: 'correct horse battery staple',
        ),
      ],
      signInGate: signInGate,
    );
    await tester.pumpAuthScreen(
      const AuthSignInScreen(),
      backendRepository: backendRepository,
    );

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-sign-in-email-field')),
      'collector@example.com',
    );
    await tester.enterText(
      _textFieldIn(const ValueKey('auth-sign-in-password-field')),
      'correct horse battery staple',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pump();

    final loadingButton = tester.widget<TextButton>(
      _textButtonIn(const ValueKey('auth-sign-in-submit')),
    );
    expect(backendRepository.signInCalls, 1);
    expect(find.text('Signing In'), findsOneWidget);
    expect(loadingButton.onPressed, isNull);

    signInGate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('S05 authenticated success wins over local guest mode', (
    tester,
  ) async {
    final backendRepository = InMemoryAuthBackendRepository(
      accounts: const [
        InMemoryAuthAccount(
          email: 'collector@example.com',
          password: 'correct horse battery staple',
        ),
      ],
    );
    final container = await tester.pumpAuthScreenWithContainer(
      const AuthSignInScreen(),
      backendRepository: backendRepository,
      guestModeRepository: const _ImmediateGuestModeRepository(chosen: true),
    );

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-sign-in-email-field')),
      'collector@example.com',
    );
    await tester.enterText(
      _textFieldIn(const ValueKey('auth-sign-in-password-field')),
      'correct horse battery staple',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-sign-in-submit')));
    await tester.pumpAndSettle();

    expect(backendRepository.signInCalls, 1);
    expect(container.read(authControllerProvider).isSignedIn, isTrue);
    expect(await container.read(guestModeControllerProvider.future), isTrue);
  });
  testWidgets('S05 Forgot Password routes to S06 with valid email prefill', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-sign-in-email-field')),
      'collector@example.com',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('auth-forgot-password-link')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('auth-forgot-password-screen')),
      findsOneWidget,
    );
    final emailField = tester.widget<TextField>(
      _textFieldIn(const ValueKey('auth-forgot-email-field')),
    );
    expect(emailField.controller?.text, 'collector@example.com');
    expect(find.text('Reset your password'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-forgot-password-placeholder-screen')),
      findsNothing,
    );
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

  testWidgets('S03 valid local Verify routes to S04', (tester) async {
    await tester.pumpAuthScreen(
      const AuthVerifyEmailScreen(email: 'collector@example.com'),
    );

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-verify-email-otp-field')),
      '123456',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-verify-email-verify')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('auth-create-password-screen')),
      findsOneWidget,
    );
    expect(find.text('Create your password'), findsOneWidget);
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
      '000000',
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

  testWidgets('S04 hierarchy renders frozen password contract', (tester) async {
    await tester.pumpAuthScreen(const AuthCreatePasswordScreen());

    expect(
      find.byKey(const ValueKey('auth-create-password-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-create-password-brand-identity')),
      findsOneWidget,
    );
    expect(find.text('Create your password'), findsOneWidget);
    expect(find.text('Secure your PackLox account.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-create-password-password-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-create-password-confirm-field')),
      findsOneWidget,
    );
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Use at least 12 characters'), findsOneWidget);
    expect(
      find.text('Use a memorable passphrase. Spaces and symbols are allowed.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-create-password-finish')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-create-password-back')),
      findsOneWidget,
    );
    expect(find.text('Need help?'), findsNothing);
    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsNothing);
    expect(
      find.byKey(const ValueKey('auth-forgot-password-screen')),
      findsNothing,
    );
  });

  testWidgets('S04 Finish disabled for empty and short password', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthCreatePasswordScreen());

    TextButton finishButton = tester.widget(
      _textButtonIn(const ValueKey('auth-create-password-finish')),
    );
    expect(finishButton.onPressed, isNull);

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-create-password-password-field')),
      'short pass!',
    );
    await tester.enterText(
      _textFieldIn(const ValueKey('auth-create-password-confirm-field')),
      'short pass!',
    );
    await tester.pump();

    finishButton = tester.widget(
      _textButtonIn(const ValueKey('auth-create-password-finish')),
    );
    expect(finishButton.onPressed, isNull);
  });

  testWidgets('S04 Finish disabled for confirm mismatch', (tester) async {
    await tester.pumpAuthScreen(const AuthCreatePasswordScreen());

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-create-password-password-field')),
      'memorable passphrase!',
    );
    await tester.enterText(
      _textFieldIn(const ValueKey('auth-create-password-confirm-field')),
      'different passphrase!',
    );
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    final finishButton = tester.widget<TextButton>(
      _textButtonIn(const ValueKey('auth-create-password-finish')),
    );
    expect(finishButton.onPressed, isNull);
  });

  testWidgets(
    'S04 Finish enabled for valid 12 plus matching password with symbols',
    (tester) async {
      await tester.pumpAuthScreen(const AuthCreatePasswordScreen());

      await tester.enterText(
        _textFieldIn(const ValueKey('auth-create-password-password-field')),
        'memorable passphrase!',
      );
      await tester.enterText(
        _textFieldIn(const ValueKey('auth-create-password-confirm-field')),
        'memorable passphrase!',
      );
      await tester.pump();

      final finishButton = tester.widget<TextButton>(
        _textButtonIn(const ValueKey('auth-create-password-finish')),
      );
      expect(finishButton.onPressed, isNotNull);

      await tester.tap(
        find.byKey(const ValueKey('auth-create-password-finish')),
      );
      await tester.pump();

      expect(
        find.textContaining('Authenticated Home handoff is pending'),
        findsOneWidget,
      );
    },
  );

  testWidgets('S04 visibility toggles work independently', (tester) async {
    await tester.pumpAuthScreen(const AuthCreatePasswordScreen());

    TextField password = tester.widget(
      _textFieldIn(const ValueKey('auth-create-password-password-field')),
    );
    TextField confirm = tester.widget(
      _textFieldIn(const ValueKey('auth-create-password-confirm-field')),
    );
    expect(password.obscureText, isTrue);
    expect(confirm.obscureText, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('auth-create-password-password-visibility')),
    );
    await tester.pump();

    password = tester.widget(
      _textFieldIn(const ValueKey('auth-create-password-password-field')),
    );
    confirm = tester.widget(
      _textFieldIn(const ValueKey('auth-create-password-confirm-field')),
    );
    expect(password.obscureText, isFalse);
    expect(confirm.obscureText, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('auth-create-password-confirm-visibility')),
    );
    await tester.pump();

    confirm = tester.widget(
      _textFieldIn(const ValueKey('auth-create-password-confirm-field')),
    );
    expect(confirm.obscureText, isFalse);
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

  testWidgets('S06 hierarchy renders frozen forgot password contract', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthForgotPasswordScreen());

    expect(
      find.byKey(const ValueKey('auth-forgot-password-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-forgot-password-brand-identity')),
      findsOneWidget,
    );
    expect(find.text('Reset your password'), findsOneWidget);
    expect(
      find.text(
        "Enter your email and we'll send reset instructions if the account exists.",
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-forgot-email-field')),
      findsOneWidget,
    );
    expect(find.text('Email address'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-forgot-submit')), findsOneWidget);
    expect(find.text('Send reset instructions'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-forgot-return-sign-in')),
      findsOneWidget,
    );
    expect(find.text('Back to Sign In'), findsOneWidget);
    expect(find.text('Check your email'), findsNothing);
    expect(find.textContaining('S07'), findsNothing);
  });

  testWidgets('S06 Send disabled for empty or invalid email', (tester) async {
    final repository = _InteractiveAuthRepository();
    await tester.pumpAuthScreen(
      const AuthForgotPasswordScreen(),
      repository: repository,
    );

    TextButton sendButton = tester.widget(
      _textButtonIn(const ValueKey('auth-forgot-submit')),
    );
    expect(sendButton.onPressed, isNull);

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-forgot-email-field')),
      'not-an-email',
    );
    await tester.pump();

    sendButton = tester.widget(
      _textButtonIn(const ValueKey('auth-forgot-submit')),
    );
    expect(sendButton.onPressed, isNull);
    expect(repository.passwordResetCalls, 0);
  });

  testWidgets('S06 submit shows generic confirmation and stays on S06', (
    tester,
  ) async {
    final repository = _InteractiveAuthRepository();
    await tester.pumpAuthScreen(
      const AuthForgotPasswordScreen(),
      repository: repository,
    );

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-forgot-email-field')),
      'reset@example.com',
    );
    await tester.pump();

    final sendButton = tester.widget<TextButton>(
      _textButtonIn(const ValueKey('auth-forgot-submit')),
    );
    expect(sendButton.onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('auth-forgot-submit')));
    await tester.pump();

    expect(repository.passwordResetCalls, 0);
    expect(
      find.byKey(const ValueKey('auth-forgot-password-screen')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('auth-forgot-confirmation')),
      findsOneWidget,
    );
    expect(find.text('Check your email'), findsOneWidget);
    expect(
      find.text(
        'If an account exists for this email, reset instructions have been sent.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('auth-forgot-email-field')), findsNothing);
    expect(
      find.textContaining('account exists for this email'),
      findsOneWidget,
    );
    expect(find.textContaining('account not found'), findsNothing);
    expect(find.textContaining('S07'), findsNothing);
  });

  testWidgets('S06 resend instructions uses 30 second cooldown', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthForgotPasswordScreen());

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-forgot-email-field')),
      'reset@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-forgot-submit')));
    await tester.pump();

    expect(find.text('You can resend instructions in 30s.'), findsOneWidget);
    expect(find.byKey(const ValueKey('auth-forgot-resend')), findsNothing);

    await tester.pump(const Duration(seconds: 31));

    expect(find.byKey(const ValueKey('auth-forgot-resend')), findsOneWidget);
    expect(find.text('Resend instructions'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('auth-forgot-resend')));
    await tester.pump();

    expect(find.text('You can resend instructions in 30s.'), findsOneWidget);
  });

  testWidgets('S06 five request local limit shows neutral rate limit', (
    tester,
  ) async {
    await tester.pumpAuthScreen(const AuthForgotPasswordScreen());

    await tester.enterText(
      _textFieldIn(const ValueKey('auth-forgot-email-field')),
      'reset@example.com',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('auth-forgot-submit')));
    await tester.pump();

    for (var index = 0; index < 4; index += 1) {
      await tester.pump(const Duration(seconds: 31));
      await tester.tap(find.byKey(const ValueKey('auth-forgot-resend')));
      await tester.pump();
    }

    expect(
      find.byKey(const ValueKey('auth-forgot-rate-limit')),
      findsOneWidget,
    );
    expect(
      find.text(
        "We couldn't send more instructions right now. Please wait and try again.",
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('auth-forgot-resend')), findsNothing);
  });

  testWidgets('S06 Back to Sign In returns to S05', (tester) async {
    await tester.pumpAuthScreen(const AuthSignInScreen());

    await tester.tap(find.byKey(const ValueKey('auth-forgot-password-link')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('auth-forgot-password-screen')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('auth-forgot-return-sign-in')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-sign-in-screen')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth-forgot-password-screen')),
      findsNothing,
    );
  });

  testWidgets('Guest return remains available without auth guard', (
    tester,
  ) async {
    await tester.pumpAuthRoute(route: () => AuthWelcomeScreen.route());

    expect(
      find.byKey(const ValueKey('auth-welcome-explore-guest')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('auth-welcome-explore-guest')),
    );
    await tester.tap(find.byKey(const ValueKey('auth-welcome-explore-guest')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('auth-welcome-screen')), findsNothing);
    expect(find.byKey(const ValueKey('open-auth-route')), findsOneWidget);
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

    expect(
      find.byKey(const ValueKey('auth-sign-in-scroll-view')),
      findsOneWidget,
    );
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
    AuthBackendRepository? backendRepository,
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    await pumpAuthScreenWithContainer(
      child,
      repository: repository,
      backendRepository: backendRepository,
      themeMode: themeMode,
    );
  }

  Future<ProviderContainer> pumpAuthScreenWithContainer(
    Widget child, {
    AuthRepository? repository,
    AuthBackendRepository? backendRepository,
    GuestModeRepository? guestModeRepository,
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    final overrides = [
      authRepositoryProvider.overrideWithValue(
        repository ?? _InteractiveAuthRepository(),
      ),
      if (backendRepository != null)
        authBackendRepositoryProvider.overrideWithValue(backendRepository),
      if (guestModeRepository != null)
        guestModeRepositoryProvider.overrideWithValue(guestModeRepository),
    ];
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);

    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: Scaffold(body: child),
        ),
      ),
    );
    await pump();
    return container;
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

class _ImmediateGuestModeRepository implements GuestModeRepository {
  const _ImmediateGuestModeRepository({required this.chosen});

  final bool chosen;

  @override
  Future<bool> hasChosenGuestMode() async => chosen;

  @override
  Future<void> setGuestModeChosen(bool chosen) async {}
}

class _InteractiveAuthRepository implements AuthRepository {
  _InteractiveAuthRepository({AppUser? initialUser}) : _user = initialUser;

  AppUser? _user;
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
