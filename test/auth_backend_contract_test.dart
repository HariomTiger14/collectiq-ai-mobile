import 'package:collectiq_ai/core/navigation/app_shell.dart';
import 'package:collectiq_ai/core/supabase/supabase_auth_response_normalizer.dart';
import 'package:collectiq_ai/features/auth/data/repositories/auth_repository_backend_adapter.dart';
import 'package:collectiq_ai/features/auth/data/services/signup_start_guard_client.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_backend_contract.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_backend_repository.dart';
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

    test(
      'existing email signup fails safely without auth or overwrite',
      () async {
        final repository = InMemoryAuthBackendRepository(
          accounts: const [
            InMemoryAuthAccount(
              email: 'collector@example.com',
              password: 'original passphrase',
            ),
          ],
        );
        final container = _contractContainer(repository);
        addTearDown(container.dispose);
        final controller = container.read(
          authBackendContractControllerProvider.notifier,
        );

        await controller.startEmailSignup(email: 'Collector@Example.com');

        final state = container.read(authBackendContractControllerProvider);
        expect(state.status, AuthBackendContractStatus.signedOut);
        expect(
          state.failure?.code,
          AuthBackendFailureCode.accountExistenceNotDisclosed,
        );
        expect(state.infoMessage, authSignupStartBlockedMessage);
        expect(state.infoMessage, isNot(contains('registered')));
        expect(state.infoMessage, isNot(contains('already')));
        expect(state.infoMessage, isNot(contains('exists')));
        expect(state.user, isNull);
        expect(repository.currentSignedInUser, isNull);
        expect(repository.passwordCreateCalls, 0);

        final newPasswordResult = await repository.signInWithEmailPassword(
          email: 'collector@example.com',
          password: 'new passphrase should not work',
        );
        expect(
          newPasswordResult.failure?.code,
          AuthBackendFailureCode.invalidCredentialsNeutral,
        );
      },
    );

    test(
      'signup start requires explicit account-creation safety before verification',
      () async {
        final repository = InMemoryAuthBackendRepository(
          signupStartSafeForAccountCreation: false,
        );
        final container = _contractContainer(repository);
        addTearDown(container.dispose);

        await container
            .read(authBackendContractControllerProvider.notifier)
            .startEmailSignup(email: 'new@example.com');

        final state = container.read(authBackendContractControllerProvider);
        expect(state.status, AuthBackendContractStatus.signedOut);
        expect(
          state.failure?.code,
          AuthBackendFailureCode.accountExistenceNotDisclosed,
        );
        expect(state.infoMessage, authSignupStartBlockedMessage);
        expect(repository.signupStartCalls, 1);
        expect(repository.currentSignedInUser, isNull);
      },
    );

    test('OTP verify success and failure map attempts safely', () async {
      final repository = InMemoryAuthBackendRepository();
      final container = _contractContainer(repository);
      addTearDown(container.dispose);
      final controller = container.read(
        authBackendContractControllerProvider.notifier,
      );

      await controller.startEmailSignup(email: 'collector@example.com');
      await controller.verifyEmailOtp(code: '00000000');

      var state = container.read(authBackendContractControllerProvider);
      expect(state.status, AuthBackendContractStatus.verificationSent);
      expect(state.failure?.code, AuthBackendFailureCode.otpInvalid);
      expect(state.attemptsRemaining, 4);

      await controller.verifyEmailOtp(code: '12345678');

      state = container.read(authBackendContractControllerProvider);
      expect(state.status, AuthBackendContractStatus.otpVerified);
      expect(state.verification?.email, 'collector@example.com');
    });

    test('expired or reused OTP maps to safe retry state', () async {
      final repository = InMemoryAuthBackendRepository(
        otpVerifyFailure: const AuthBackendFailure(
          AuthBackendFailureCode.otpExpired,
        ),
      );
      final container = _contractContainer(repository);
      addTearDown(container.dispose);
      final controller = container.read(
        authBackendContractControllerProvider.notifier,
      );

      await controller.startEmailSignup(email: 'collector@example.com');
      await controller.verifyEmailOtp(code: '12345678');

      final state = container.read(authBackendContractControllerProvider);
      expect(state.status, AuthBackendContractStatus.verificationSent);
      expect(state.failure?.code, AuthBackendFailureCode.otpExpired);
      expect(state.infoMessage, 'Code expired. Request a new code.');
      expect(state.isSignedIn, isFalse);
      expect(repository.currentSignedInUser, isNull);
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
          await controller.verifyEmailOtp(code: '00000000');
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
      await controller.verifyEmailOtp(code: '12345678');
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
      'create password requires verified backend state before repository call',
      () async {
        final repository = InMemoryAuthBackendRepository();
        final container = _contractContainer(repository);
        addTearDown(container.dispose);
        final controller = container.read(
          authBackendContractControllerProvider.notifier,
        );

        await controller.createPasswordAfterVerification(
          password: 'memorable passphrase!',
          confirmPassword: 'memorable passphrase!',
        );

        final state = container.read(authBackendContractControllerProvider);
        expect(state.status, AuthBackendContractStatus.verificationSent);
        expect(state.failure?.code, AuthBackendFailureCode.otpInvalid);
        expect(repository.passwordCreateCalls, 0);
        expect(state.isSignedIn, isFalse);
        expect(repository.currentSignedInUser, isNull);
      },
    );

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

  group('Supabase OTP signup normalizer capability', () {
    test(
      'normalizes OTP signup, verification, and password update success',
      () {
        final otpStart = SupabaseAuthResponseNormalizer.normalizeResponse(
          action: SupabaseAuthAction.otpSignupStart,
          statusCode: 200,
          body: const <String, dynamic>{},
        );
        expect(otpStart.status, SupabaseAuthNormalizedStatus.otpSent);

        final otpVerify = SupabaseAuthResponseNormalizer.normalizeResponse(
          action: SupabaseAuthAction.otpVerify,
          statusCode: 200,
          body: const {
            'access_token': 'otp-session-token',
            'user': {'id': 'new-user', 'email': 'new@example.com'},
          },
        );
        expect(otpVerify.status, SupabaseAuthNormalizedStatus.otpVerified);

        final passwordUpdate = SupabaseAuthResponseNormalizer.normalizeResponse(
          action: SupabaseAuthAction.passwordUpdate,
          statusCode: 200,
          body: const {'id': 'new-user', 'email': 'new@example.com'},
        );
        expect(
          passwordUpdate.status,
          SupabaseAuthNormalizedStatus.passwordUpdated,
        );
      },
    );
  });

  group('AuthRepositoryBackendAdapter OTP signup capability spike', () {
    test(
      'uses optional OTP signup repository methods after guard allows',
      () async {
        final repository = _OtpCapableAuthRepository();
        final guard = _SignupStartGuardFake();
        final adapter = AuthRepositoryBackendAdapter(
          repository: repository,
          signupStartGuard: guard,
        );

        final start = await adapter.startEmailSignup(
          email: ' NewUser@Example.com ',
        );
        expect(start.isSuccess, isTrue);
        expect(start.requireValue.email, 'newuser@example.com');
        expect(start.requireValue.safeForAccountCreation, isTrue);
        expect(repository.signupStartCalls, 1);
        expect(repository.lastSignupEmail, 'newuser@example.com');
        expect(guard.calls, 1);
        expect(guard.lastEmail, 'newuser@example.com');

        final verification = await adapter.verifyEmailOtp(
          email: 'NewUser@Example.com',
          code: '12345678',
        );
        expect(verification.isSuccess, isTrue);
        expect(verification.requireValue.email, 'newuser@example.com');
        expect(repository.otpVerifyCalls, 1);

        final password = await adapter.createPasswordAfterVerification(
          verification: verification.requireValue,
          password: 'correct horse battery staple',
        );
        expect(password.isSuccess, isTrue);
        expect(password.requireValue.email, 'newuser@example.com');
        expect(repository.passwordCreateCalls, 1);

        final resend = await adapter.resendVerificationCode(
          email: 'NewUser@Example.com',
        );
        expect(resend.isSuccess, isTrue);
        expect(repository.signupStartCalls, 2);
      },
    );

    test('blocked signup-start guard never sends Supabase OTP', () async {
      final repository = _OtpCapableAuthRepository();
      final adapter = AuthRepositoryBackendAdapter(
        repository: repository,
        signupStartGuard: _SignupStartGuardFake(safeForAccountCreation: false),
      );

      final start = await adapter.startEmailSignup(email: 'known@example.com');

      expect(start.isSuccess, isFalse);
      expect(
        start.failure?.code,
        AuthBackendFailureCode.accountExistenceNotDisclosed,
      );
      expect(start.failure?.safeMessage, authSignupStartBlockedMessage);
      expect(repository.signupStartCalls, 0);
    });

    test(
      'signup-start guard failure stays retryable and skips Supabase OTP',
      () async {
        final repository = _OtpCapableAuthRepository();
        final adapter = AuthRepositoryBackendAdapter(
          repository: repository,
          signupStartGuard: _SignupStartGuardFake(
            error: const AuthException('Network connection failed.'),
          ),
        );

        final start = await adapter.startEmailSignup(email: 'new@example.com');

        expect(start.isSuccess, isFalse);
        expect(start.failure?.code, AuthBackendFailureCode.networkOffline);
        expect(repository.signupStartCalls, 0);
      },
    );

    test(
      'returns capability unavailable when repository lacks OTP support',
      () async {
        final adapter = AuthRepositoryBackendAdapter(
          repository: const _ShellAuthRepository(),
        );

        final start = await adapter.startEmailSignup(email: 'new@example.com');
        final verify = await adapter.verifyEmailOtp(
          email: 'new@example.com',
          code: '12345678',
        );
        final password = await adapter.createPasswordAfterVerification(
          verification: EmailOtpVerification(
            email: 'new@example.com',
            verifiedAt: DateTime.utc(2026, 7, 18),
          ),
          password: 'correct horse battery staple',
        );

        expect(
          start.failure?.code,
          AuthBackendFailureCode.capabilityUnavailable,
        );
        expect(
          verify.failure?.code,
          AuthBackendFailureCode.capabilityUnavailable,
        );
        expect(
          password.failure?.code,
          AuthBackendFailureCode.capabilityUnavailable,
        );
      },
    );

    test('maps OTP signup failures to UI-safe categories', () async {
      final existingEmailAdapter = AuthRepositoryBackendAdapter(
        repository: _OtpCapableAuthRepository(
          startError: const AuthException('User already registered'),
        ),
        signupStartGuard: _SignupStartGuardFake(),
      );
      final existingEmail = await existingEmailAdapter.startEmailSignup(
        email: 'known@example.com',
      );
      expect(
        existingEmail.failure?.code,
        AuthBackendFailureCode.accountExistenceNotDisclosed,
      );
      expect(existingEmail.failure?.safeMessage, isNot(contains('registered')));

      final invalidOtpAdapter = AuthRepositoryBackendAdapter(
        repository: _OtpCapableAuthRepository(
          verifyError: const AuthException('Invalid OTP token'),
        ),
        signupStartGuard: _SignupStartGuardFake(),
      );
      final invalidOtp = await invalidOtpAdapter.verifyEmailOtp(
        email: 'new@example.com',
        code: '00000000',
      );
      expect(invalidOtp.failure?.code, AuthBackendFailureCode.otpInvalid);

      final configFailureAdapter = AuthRepositoryBackendAdapter(
        repository: _OtpCapableAuthRepository(
          verifyError: const AuthException(
            'Supabase anon key is missing from SIT config.',
          ),
        ),
        signupStartGuard: _SignupStartGuardFake(),
      );
      final configFailure = await configFailureAdapter.verifyEmailOtp(
        email: 'new@example.com',
        code: '12345678',
      );
      expect(
        configFailure.failure?.code,
        AuthBackendFailureCode.networkOffline,
      );
      expect(
        configFailure.failure?.safeMessage,
        authOtpVerificationRetryableMessage,
      );
      expect(
        configFailure.failure?.safeMessage,
        isNot('This authentication step is not available yet.'),
      );

      final sessionExpiredAdapter = AuthRepositoryBackendAdapter(
        repository: _OtpCapableAuthRepository(
          passwordError: const AuthException('Verified auth session missing'),
        ),
      );
      final sessionExpired = await sessionExpiredAdapter
          .createPasswordAfterVerification(
            verification: EmailOtpVerification(
              email: 'new@example.com',
              verifiedAt: DateTime.utc(2026, 7, 18),
            ),
            password: 'correct horse battery staple',
          );
      expect(sessionExpired.failure?.code, AuthBackendFailureCode.otpExpired);
      expect(
        sessionExpired.failure?.safeMessage,
        'Verification expired. Request a new code.',
      );
    });

    test('password reset config failures map to safe retryable copy', () async {
      final adapter = AuthRepositoryBackendAdapter(
        repository: const _ResetFailingAuthRepository(
          AuthException('Supabase anon key is missing from SIT config.'),
        ),
      );

      final reset = await adapter.requestPasswordReset(
        email: 'unknown@example.com',
      );

      expect(reset.isSuccess, isFalse);
      expect(reset.failure?.safeMessage, authResetRequestRetryableMessage);
      expect(reset.failure?.safeMessage, isNot(contains('anon key')));
      expect(reset.failure?.safeMessage, isNot(contains('Supabase')));
    });
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

ProviderContainer _contractContainer(AuthBackendRepository repository) {
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

class _ResetFailingAuthRepository extends _ShellAuthRepository {
  const _ResetFailingAuthRepository(this.error);

  final Object error;

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    throw error;
  }
}

class _SignupStartGuardFake implements SignupStartGuardClient {
  _SignupStartGuardFake({this.safeForAccountCreation = true, this.error});

  final bool safeForAccountCreation;
  final Object? error;
  var calls = 0;
  String? lastEmail;

  @override
  Future<SignupStartGuardResult> start({required String email}) async {
    calls += 1;
    lastEmail = email.trim().toLowerCase();
    final configuredError = error;
    if (configuredError != null) {
      throw configuredError;
    }
    return SignupStartGuardResult(
      safeForAccountCreation: safeForAccountCreation,
    );
  }
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

class _OtpCapableAuthRepository
    implements AuthRepository, OtpSignupAuthRepository {
  _OtpCapableAuthRepository({
    this.startError,
    this.verifyError,
    this.passwordError,
  });

  final Object? startError;
  final Object? verifyError;
  final Object? passwordError;
  var signupStartCalls = 0;
  var otpVerifyCalls = 0;
  var passwordCreateCalls = 0;
  String? lastSignupEmail;
  String? lastVerifyEmail;
  String? lastVerifyCode;
  String? lastPassword;

  @override
  Future<AppUser?> currentUser() async => null;

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
    return emailPasswordUser(email: email.trim().toLowerCase());
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return emailPasswordUser(email: email.trim().toLowerCase());
  }

  @override
  Future<void> startEmailOtpSignup({required String email}) async {
    signupStartCalls += 1;
    lastSignupEmail = email.trim().toLowerCase();
    final error = startError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<EmailOtpVerification> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    otpVerifyCalls += 1;
    lastVerifyEmail = email.trim().toLowerCase();
    lastVerifyCode = code;
    final error = verifyError;
    if (error != null) {
      throw error;
    }
    return EmailOtpVerification(
      email: email.trim().toLowerCase(),
      verifiedAt: DateTime.utc(2026, 7, 18),
    );
  }

  @override
  Future<AppUser> createPasswordAfterOtp({required String password}) async {
    passwordCreateCalls += 1;
    lastPassword = password;
    final error = passwordError;
    if (error != null) {
      throw error;
    }
    return emailPasswordUser(email: lastVerifyEmail ?? 'new@example.com');
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
