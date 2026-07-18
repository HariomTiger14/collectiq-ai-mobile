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
    this.expectedOtp = '123456',
    this.networkOffline = false,
  }) {
    for (final account in accounts) {
      _accounts[_normalize(account.email)] = account;
    }
  }

  final String expectedOtp;
  final bool networkOffline;
  final _accounts = <String, InMemoryAuthAccount>{};
  final _pendingSignupEmails = <String>{};
  final _verifiedEmails = <String, EmailOtpVerification>{};
  final _attemptsByEmail = <String, int>{};
  AppUser? _currentUser;

  int signInCalls = 0;
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
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    final normalized = _normalize(email);
    _pendingSignupEmails.add(normalized);
    _attemptsByEmail[normalized] = 0;
    return AuthBackendResult.success(EmailSignupStart(email: normalized));
  }

  @override
  Future<AuthBackendResult<EmailOtpVerification>> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    otpVerifyCalls += 1;
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
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    final normalized = _normalize(verification.email);
    if (_verifiedEmails[normalized]?.verificationToken !=
        verification.verificationToken) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.otpExpired),
      );
    }
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
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    final normalized = _normalize(email);
    _pendingSignupEmails.add(normalized);
    _attemptsByEmail[normalized] = 0;
    return AuthBackendResult.success(EmailSignupStart(email: normalized));
  }

  @override
  Future<AuthBackendResult<PasswordResetRequestResult>> requestPasswordReset({
    required String email,
  }) async {
    resetCalls += 1;
    if (networkOffline) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(AuthBackendFailureCode.networkOffline),
      );
    }
    return AuthBackendResult.success(
      PasswordResetRequestResult(email: _normalize(email)),
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
