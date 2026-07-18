import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_backend_contract.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/guest_mode_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_backend_contract_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/guest_mode_controller.dart';
import 'package:collectiq_ai/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'support/in_memory_auth_backend_repository.dart';

void main() {
  group('Auth backend contract controller', () {
    test('sign-in success stores cloud user', () async {
      final repository = InMemoryAuthBackendRepository(
        accounts: const [
          InMemoryAuthAccount(
            email: 'collector@example.com',
            password: 'correct horse battery staple',
          ),
        ],
      );
      final container = _contractContainer(repository);
      addTearDown(container.dispose);

      await container
          .read(authBackendContractControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'collector@example.com',
            password: 'correct horse battery staple',
          );

      final state = container.read(authBackendContractControllerProvider);
      expect(state.status, AuthBackendContractStatus.signedIn);
      expect(state.isSignedIn, isTrue);
      expect(state.user?.email, 'collector@example.com');
      expect(repository.signInCalls, 1);
    });

    test(
      'sign-in failures use neutral copy and hide account existence',
      () async {
        final repository = InMemoryAuthBackendRepository();
        final container = _contractContainer(repository);
        addTearDown(container.dispose);

        await container
            .read(authBackendContractControllerProvider.notifier)
            .signInWithEmailPassword(
              email: 'missing@example.com',
              password: 'wrong password',
            );

        final state = container.read(authBackendContractControllerProvider);
        expect(state.status, AuthBackendContractStatus.signedOut);
        expect(
          state.failure?.code,
          AuthBackendFailureCode.invalidCredentialsNeutral,
        );
        expect(state.infoMessage, 'Email or password is not correct.');
        expect(state.infoMessage, isNot(contains('account')));
        expect(state.infoMessage, isNot(contains('not found')));
      },
    );

    test('signup start creates email verification placeholder path', () async {
      final repository = InMemoryAuthBackendRepository();
      final container = _contractContainer(repository);
      addTearDown(container.dispose);

      await container
          .read(authBackendContractControllerProvider.notifier)
          .startEmailSignup(email: 'NewUser@Example.com ');

      final state = container.read(authBackendContractControllerProvider);
      expect(state.status, AuthBackendContractStatus.verificationSent);
      expect(state.email, 'newuser@example.com');
      expect(state.cooldownRemaining, const Duration(seconds: 30));
      expect(repository.signupStartCalls, 1);
    });

    test('OTP verify success and failure map attempts safely', () async {
      final repository = InMemoryAuthBackendRepository();
      final container = _contractContainer(repository);
      addTearDown(container.dispose);
      final controller = container.read(
        authBackendContractControllerProvider.notifier,
      );

      await controller.startEmailSignup(email: 'collector@example.com');
      await controller.verifyEmailOtp(code: '000000');

      var state = container.read(authBackendContractControllerProvider);
      expect(state.status, AuthBackendContractStatus.verificationSent);
      expect(state.failure?.code, AuthBackendFailureCode.otpInvalid);
      expect(state.attemptsRemaining, 4);

      await controller.verifyEmailOtp(code: '123456');

      state = container.read(authBackendContractControllerProvider);
      expect(state.status, AuthBackendContractStatus.otpVerified);
      expect(state.verification?.email, 'collector@example.com');
    });

    test(
      'OTP attempt limit requires resend before verification can continue',
      () async {
        final repository = InMemoryAuthBackendRepository();
        final container = _contractContainer(repository);
        addTearDown(container.dispose);
        final controller = container.read(
          authBackendContractControllerProvider.notifier,
        );

        await controller.startEmailSignup(email: 'collector@example.com');
        for (var i = 0; i < 6; i += 1) {
          await controller.verifyEmailOtp(code: '000000');
        }

        var state = container.read(authBackendContractControllerProvider);
        expect(
          state.failure?.code,
          AuthBackendFailureCode.otpAttemptLimitReached,
        );
        expect(state.attemptsRemaining, 0);

        await controller.resendVerificationCode();
        state = container.read(authBackendContractControllerProvider);
        expect(state.status, AuthBackendContractStatus.verificationSent);
        expect(state.attemptsRemaining, 5);
        expect(state.infoMessage, 'A new code has been sent.');
      },
    );

    test('create password enforces frozen S04 policy compatibility', () async {
      final repository = InMemoryAuthBackendRepository();
      final container = _contractContainer(repository);
      addTearDown(container.dispose);
      final controller = container.read(
        authBackendContractControllerProvider.notifier,
      );

      await controller.startEmailSignup(email: 'collector@example.com');
      await controller.verifyEmailOtp(code: '123456');
      await controller.createPasswordAfterVerification(
        password: 'short',
        confirmPassword: 'short',
      );

      var state = container.read(authBackendContractControllerProvider);
      expect(state.status, AuthBackendContractStatus.otpVerified);
      expect(
        state.failure?.code,
        AuthBackendFailureCode.passwordPolicyMismatch,
      );
      expect(state.infoMessage, 'Use at least 12 characters.');
      expect(repository.passwordCreateCalls, 0);

      await controller.createPasswordAfterVerification(
        password: 'twelve chars!',
        confirmPassword: 'twelve chars!',
      );

      state = container.read(authBackendContractControllerProvider);
      expect(state.status, AuthBackendContractStatus.signedIn);
      expect(state.user?.email, 'collector@example.com');
      expect(repository.passwordCreateCalls, 1);
    });

    test(
      'reset request returns generic success for registered and unknown email',
      () async {
        final repository = InMemoryAuthBackendRepository(
          accounts: const [
            InMemoryAuthAccount(
              email: 'collector@example.com',
              password: 'correct horse battery staple',
            ),
          ],
        );
        final container = _contractContainer(repository);
        addTearDown(container.dispose);
        final controller = container.read(
          authBackendContractControllerProvider.notifier,
        );

        await controller.requestPasswordReset(email: 'collector@example.com');
        final registeredState = container.read(
          authBackendContractControllerProvider,
        );

        await controller.requestPasswordReset(email: 'unknown@example.com');
        final unknownState = container.read(
          authBackendContractControllerProvider,
        );

        expect(
          registeredState.infoMessage,
          'If an account exists for this email, reset instructions have been sent.',
        );
        expect(unknownState.infoMessage, registeredState.infoMessage);
        expect(
          unknownState.status,
          AuthBackendContractStatus.passwordResetConfirmation,
        );
        expect(repository.resetCalls, 2);
      },
    );
  });

  group('AppShell auth precedence contract', () {
    testWidgets('guest mode never overrides authenticated session', (
      tester,
    ) async {
      await _pumpShell(
        tester,
        authRepository: _ShellAuthRepository(user: _cloudUser),
        guestModeRepository: const _ShellGuestModeRepository(chosen: true),
        onboardingRepository: const _ShellOnboardingRepository(
          completed: false,
        ),
      );

      expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-welcome-screen')), findsNothing);
      expect(find.byKey(const ValueKey('onboarding-screen')), findsNothing);
    });

    testWidgets(
      'authenticated session wins launch routing before guest branch',
      (tester) async {
        await _pumpShell(
          tester,
          authRepository: _ShellAuthRepository(user: _cloudUser),
          guestModeRepository: const _ShellGuestModeRepository(chosen: false),
          onboardingRepository: const _ShellOnboardingRepository(
            completed: false,
          ),
        );

        expect(find.byKey(const ValueKey('app-shell')), findsOneWidget);
        expect(find.byKey(const ValueKey('auth-welcome-screen')), findsNothing);
        expect(find.byKey(const ValueKey('onboarding-screen')), findsNothing);
      },
    );
  });
}

ProviderContainer _contractContainer(InMemoryAuthBackendRepository repository) {
  return ProviderContainer(
    overrides: [authBackendRepositoryProvider.overrideWithValue(repository)],
  );
}

Future<void> _pumpShell(
  WidgetTester tester, {
  required AuthRepository authRepository,
  required GuestModeRepository guestModeRepository,
  required OnboardingRepository onboardingRepository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        guestModeRepositoryProvider.overrideWithValue(guestModeRepository),
        onboardingRepositoryProvider.overrideWithValue(onboardingRepository),
      ],
      child: const MaterialApp(home: AppShell()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

const _cloudUser = AppUser(
  id: 'cloud-user',
  displayName: 'collector@example.com',
  email: 'collector@example.com',
  provider: AuthProviderType.emailPassword,
);

class _ShellAuthRepository implements AuthRepository {
  const _ShellAuthRepository({this.user});

  final AppUser? user;

  @override
  Future<AppUser?> currentUser() async => user;

  @override
  Future<AppUser> signIn() => signInAnonymously();

  @override
  Future<AppUser> signInAnonymously() async {
    return const AppUser(
      id: 'local-user',
      displayName: 'Local Collector',
      email: null,
      isAnonymous: true,
      isLocalOnly: true,
      provider: AuthProviderType.localAnonymous,
    );
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _cloudUser;
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return _cloudUser;
  }

  @override
  Future<void> resendEmailConfirmation({required String email}) async {}

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {}

  @override
  Future<AppUser> signInWithGoogle() {
    throw const AuthException('Google sign-in is not enabled.');
  }

  @override
  Future<AppUser> signInWithApple() {
    throw const AuthException('Apple sign-in is not enabled.');
  }

  @override
  Future<void> signOut() async {}
}

class _ShellGuestModeRepository implements GuestModeRepository {
  const _ShellGuestModeRepository({required this.chosen});

  final bool chosen;

  @override
  Future<bool> hasChosenGuestMode() async => chosen;

  @override
  Future<void> setGuestModeChosen(bool chosen) async {}
}

class _ShellOnboardingRepository implements OnboardingRepository {
  const _ShellOnboardingRepository({required this.completed});

  final bool completed;

  @override
  Future<bool> hasCompletedOnboarding() async => completed;

  @override
  Future<void> setOnboardingCompleted(bool completed) async {}
}
