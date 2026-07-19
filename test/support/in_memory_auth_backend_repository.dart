import 'dart:async';

import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_backend_contract.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_backend_repository.dart';

class InMemoryAuthAccount {
  const InMemoryAuthAccount({
    required this.email,
    required this.password,
    this.emailVerified = true,
  });

  final String email;
  final String password;
  final bool emailVerified;
}

class InMemoryAuthBackendRepository implements AuthBackendRepository {
  InMemoryAuthBackendRepository({
    Iterable<InMemoryAuthAccount> accounts = const [],
    this.expectedOtp = '12345678',
    this.networkOffline = false,
    this.signupStartGate,
    this.otpVerifyGate,
    this.passwordCreateGate,
    this.signInGate,
    this.resetGate,
    this.otpVerifyFailure,
    this.passwordCreateFailure,
    this.resetFailure,
    this.signupStartSafeForAccountCreation = true,
    this.resetUnknownAsAccountExistenceFailure = false,
  }) {
    for (final account in accounts) {
      _accounts[_normalize(account.email)] = account;
    }
  }

  final String expectedOtp;
  final bool networkOffline;
  final Completer<void>? signupStartGate;
  final Completer<void>? otpVerifyGate;
  final Completer<void>? passwordCreateGate;
  final Completer<void>? signInGate;
  final Completer<void>? resetGate;
  final AuthBackendFailure? otpVerifyFailure;
  final AuthBackendFailure? passwordCreateFailure;
  final AuthBackendFailure? resetFailure;
  final bool signupStartSafeForAccountCreation;
  final bool resetUnknownAsAccountExistenceFailure;
  final _accounts = <String, InMemoryAuthAccount>{};
  final _pendingSignupEmails = <String>{};
  final _verifiedEmails = <String, EmailOtpVerification>{};
  final _attemptsByEmail = <String, int>{};
  AppUser? _currentUser;

  int signInCalls = 0;
  String? lastSignInEmail;
  String? lastSignInPassword;
  String? lastSignupEmail;
  String? lastOtpEmail;
  String? lastOtpCode;
  String? lastCreatedPasswordEmail;
  String? lastCreatedPassword;
  String? lastResendEmail;
  String? lastResetEmail;
  int signupStartCalls = 0;
  int otpVerifyCalls = 0;
  int passwordCreateCalls = 0;
  int resendCalls = 0;
  int resetCalls = 0;
  int signOutCalls = 0;

  AppUser? get currentSignedInUser => _currentUser;

  @override
  Future<AuthBackendResult<AppUser?>> currentUser() async {
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    return AuthBackendResult.success(_currentUser);
  }

  @override
  Future<AuthBackendResult<AppUser>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    lastSignInEmail = _normalize(email);
    lastSignInPassword = password;
    final gate = signInGate;
    if (gate != null) {
      await gate.future;
    }
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    final account = _accounts[_normalize(email)];
    if (account == null || account.password != password) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.invalidCredentialsNeutral),
      );
    }
    if (!account.emailVerified) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.emailNotVerified),
      );
    }
    _currentUser = emailPasswordUser(email: account.email);
    return AuthBackendResult.success(_currentUser!);
  }

  @override
  Future<AuthBackendResult<EmailSignupStart>> startEmailSignup({
    required String email,
  }) async {
    signupStartCalls += 1;
    lastSignupEmail = _normalize(email);
    final gate = signupStartGate;
    if (gate != null) {
      await gate.future;
    }
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    final normalized = _normalize(email);
    if (_accounts.containsKey(normalized)) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(
          AuthBackendFailureCode.accountExistenceNotDisclosed,
          message: authSignupStartBlockedMessage,
        ),
      );
    }
    _pendingSignupEmails.add(normalized);
    _attemptsByEmail[normalized] = 0;
    return AuthBackendResult.success(
      EmailSignupStart(
        email: normalized,
        safeForAccountCreation: signupStartSafeForAccountCreation,
      ),
    );
  }

  @override
  Future<AuthBackendResult<EmailOtpVerification>> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    otpVerifyCalls += 1;
    lastOtpEmail = _normalize(email);
    lastOtpCode = code;
    final gate = otpVerifyGate;
    if (gate != null) {
      await gate.future;
    }
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    final normalized = _normalize(email);
    if (!_pendingSignupEmails.contains(normalized)) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.otpExpired),
      );
    }
    final configuredFailure = otpVerifyFailure;
    if (configuredFailure != null) {
      return AuthBackendResult.failure(configuredFailure);
    }
    final attempts = (_attemptsByEmail[normalized] ?? 0) + 1;
    _attemptsByEmail[normalized] = attempts;
    if (attempts > 5) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(
          AuthBackendFailureCode.otpAttemptLimitReached,
          attemptsRemaining: 0,
        ),
      );
    }
    if (code != expectedOtp) {
      return AuthBackendResult.failure(
        AuthBackendFailure(
          AuthBackendFailureCode.otpInvalid,
          attemptsRemaining: 5 - attempts,
        ),
      );
    }
    final verification = EmailOtpVerification(
      email: normalized,
      verifiedAt: DateTime.utc(2026, 7, 18),
      verificationToken: 'verified:$normalized',
    );
    _verifiedEmails[normalized] = verification;
    return AuthBackendResult.success(verification);
  }

  @override
  Future<AuthBackendResult<AppUser>> createPasswordAfterVerification({
    required EmailOtpVerification verification,
    required String password,
  }) async {
    passwordCreateCalls += 1;
    final gate = passwordCreateGate;
    if (gate != null) {
      await gate.future;
    }
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    final configuredFailure = passwordCreateFailure;
    if (configuredFailure != null) {
      return AuthBackendResult.failure(configuredFailure);
    }
    final normalized = _normalize(verification.email);
    if (_verifiedEmails[normalized]?.verificationToken !=
        verification.verificationToken) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.otpExpired),
      );
    }
    lastCreatedPasswordEmail = normalized;
    lastCreatedPassword = password;
    _accounts[normalized] = InMemoryAuthAccount(
      email: normalized,
      password: password,
    );
    _currentUser = emailPasswordUser(email: normalized);
    return AuthBackendResult.success(_currentUser!);
  }

  @override
  Future<AuthBackendResult<EmailSignupStart>> resendVerificationCode({
    required String email,
  }) async {
    resendCalls += 1;
    lastResendEmail = _normalize(email);
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    final normalized = _normalize(email);
    _pendingSignupEmails.add(normalized);
    _attemptsByEmail[normalized] = 0;
    return AuthBackendResult.success(
      EmailSignupStart(email: normalized, safeForAccountCreation: true),
    );
  }

  @override
  Future<AuthBackendResult<PasswordResetRequestResult>> requestPasswordReset({
    required String email,
  }) async {
    resetCalls += 1;
    final normalized = _normalize(email);
    lastResetEmail = normalized;
    final gate = resetGate;
    if (gate != null) {
      await gate.future;
    }
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    final configuredFailure = resetFailure;
    if (configuredFailure != null) {
      return AuthBackendResult.failure(configuredFailure);
    }
    if (resetUnknownAsAccountExistenceFailure &&
        !_accounts.containsKey(normalized)) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.accountExistenceNotDisclosed),
      );
    }
    return AuthBackendResult.success(
      PasswordResetRequestResult(email: normalized),
    );
  }

  @override
  Future<AuthBackendResult<void>> signOut() async {
    signOutCalls += 1;
    _currentUser = null;
    return const AuthBackendResult<void>.success(null);
  }

  String _normalize(String email) => email.trim().toLowerCase();
}
