import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/auth/data/services/signup_start_guard_client.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_backend_contract.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_backend_repository.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';

/// Adapter from the existing auth repository to the reset backend contract.
///
/// S02-S04 signup uses a server-side guard before starting Supabase OTP.
/// Repositories that expose [OtpSignupAuthRepository] can complete the frozen
/// OTP signup path; others continue to return explicit capability gaps.
class AuthRepositoryBackendAdapter implements AuthBackendRepository {
  const AuthRepositoryBackendAdapter({
    required this.repository,
    this.signupStartGuard,
  });

  final AuthRepository repository;
  final SignupStartGuardClient? signupStartGuard;

  @override
  Future<AuthBackendResult<AppUser?>> currentUser() async {
    try {
      return AuthBackendResult.success(await repository.currentUser());
    } on Object catch (error) {
      return AuthBackendResult.failure(_failureFor(error));
    }
  }

  @override
  Future<AuthBackendResult<AppUser>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await repository.signInWithEmailPassword(
        email: email,
        password: password,
      );
      return AuthBackendResult.success(user);
    } on Object catch (error) {
      return AuthBackendResult.failure(_failureFor(error, signIn: true));
    }
  }

  @override
  Future<AuthBackendResult<EmailSignupStart>> startEmailSignup({
    required String email,
  }) async {
    if (repository is! OtpSignupAuthRepository) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(
          AuthBackendFailureCode.capabilityUnavailable,
          message: 'Mobile OTP signup is not available for this auth provider.',
        ),
      );
    }
    final otpRepository = repository as OtpSignupAuthRepository;
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final guard = signupStartGuard;
      if (guard == null) {
        return const AuthBackendResult.failure(
          AuthBackendFailure(
            AuthBackendFailureCode.capabilityUnavailable,
            message:
                'Signup start guard is not configured for this auth provider.',
          ),
        );
      }
      final guardResult = await guard.start(email: normalizedEmail);
      if (!guardResult.safeForAccountCreation) {
        return const AuthBackendResult.failure(
          AuthBackendFailure(
            AuthBackendFailureCode.accountExistenceNotDisclosed,
            message: authSignupStartBlockedMessage,
          ),
        );
      }
      await otpRepository.startEmailOtpSignup(email: normalizedEmail);
      return AuthBackendResult.success(
        EmailSignupStart(
          email: normalizedEmail,
          safeForAccountCreation: true,
          cooldownRemaining: guardResult.cooldownRemaining,
        ),
      );
    } on Object catch (error) {
      return AuthBackendResult.failure(_failureFor(error, signupStart: true));
    }
  }

  @override
  Future<AuthBackendResult<EmailOtpVerification>> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    if (repository is! OtpSignupAuthRepository) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(
          AuthBackendFailureCode.capabilityUnavailable,
          message:
              'Mobile OTP verification is not available for this auth provider.',
        ),
      );
    }
    final otpRepository = repository as OtpSignupAuthRepository;
    try {
      final verification = await otpRepository.verifyEmailOtp(
        email: email.trim().toLowerCase(),
        code: code,
      );
      return AuthBackendResult.success(verification);
    } on Object catch (error) {
      return AuthBackendResult.failure(_failureFor(error, otp: true));
    }
  }

  @override
  Future<AuthBackendResult<AppUser>> createPasswordAfterVerification({
    required EmailOtpVerification verification,
    required String password,
  }) async {
    if (repository is! OtpSignupAuthRepository) {
      return const AuthBackendResult.failure(
        AuthBackendFailure(
          AuthBackendFailureCode.capabilityUnavailable,
          message:
              'Post-OTP password creation is not available for this auth provider.',
        ),
      );
    }
    final otpRepository = repository as OtpSignupAuthRepository;
    try {
      final user = await otpRepository.createPasswordAfterOtp(
        password: password,
      );
      return AuthBackendResult.success(user);
    } on Object catch (error) {
      return AuthBackendResult.failure(
        _failureFor(error, requiresVerifiedSession: true),
      );
    }
  }

  @override
  Future<AuthBackendResult<EmailSignupStart>> resendVerificationCode({
    required String email,
  }) async {
    final otpRepository = repository;
    if (otpRepository is OtpSignupAuthRepository) {
      return startEmailSignup(email: email);
    }
    try {
      await repository.resendEmailConfirmation(email: email);
      return AuthBackendResult.success(
        EmailSignupStart(email: email, safeForAccountCreation: true),
      );
    } on Object catch (error) {
      return AuthBackendResult.failure(_failureFor(error));
    }
  }

  @override
  Future<AuthBackendResult<PasswordResetRequestResult>> requestPasswordReset({
    required String email,
  }) async {
    try {
      await repository.sendPasswordResetEmail(email: email);
      return AuthBackendResult.success(
        PasswordResetRequestResult(email: email),
      );
    } on Object catch (error) {
      final failure = _failureFor(error, passwordReset: true);
      if (failure.code == AuthBackendFailureCode.invalidCredentialsNeutral ||
          failure.code == AuthBackendFailureCode.accountExistenceNotDisclosed) {
        return AuthBackendResult.success(
          PasswordResetRequestResult(email: email),
        );
      }
      return AuthBackendResult.failure(failure);
    }
  }

  @override
  Future<AuthBackendResult<void>> signOut() async {
    try {
      await repository.signOut();
      return const AuthBackendResult.success(null);
    } on Object catch (error) {
      return AuthBackendResult.failure(_failureFor(error));
    }
  }

  AuthBackendFailure _failureFor(
    Object error, {
    bool signIn = false,
    bool signupStart = false,
    bool otp = false,
    bool requiresVerifiedSession = false,
    bool passwordReset = false,
  }) {
    final message = _messageFor(error).toLowerCase();
    if (error is SupabaseNotConfiguredException ||
        message.contains('anon key') ||
        message.contains('api key') ||
        (message.contains('supabase') && message.contains('config'))) {
      if (passwordReset) {
        return const AuthBackendFailure(
          AuthBackendFailureCode.networkOffline,
          message: authResetRequestRetryableMessage,
        );
      }
      return const AuthBackendFailure(
        AuthBackendFailureCode.capabilityUnavailable,
      );
    }
    if (message.contains('network') ||
        message.contains('internet') ||
        message.contains('connection')) {
      return const AuthBackendFailure(AuthBackendFailureCode.networkOffline);
    }
    if (message.contains('too many') || message.contains('rate')) {
      return const AuthBackendFailure(
        AuthBackendFailureCode.cooldownRateLimited,
      );
    }
    if (requiresVerifiedSession &&
        (message.contains('session') || message.contains('verified'))) {
      return const AuthBackendFailure(
        AuthBackendFailureCode.otpExpired,
        message: 'Verification expired. Request a new code.',
      );
    }
    if (otp && (message.contains('expired') || message.contains('stale'))) {
      return const AuthBackendFailure(AuthBackendFailureCode.otpExpired);
    }
    if (otp &&
        (message.contains('otp') ||
            message.contains('token') ||
            message.contains('code') ||
            message.contains('invalid'))) {
      return const AuthBackendFailure(AuthBackendFailureCode.otpInvalid);
    }
    if (signupStart &&
        (message.contains('registered') ||
            message.contains('exists') ||
            message.contains('not found'))) {
      return const AuthBackendFailure(
        AuthBackendFailureCode.accountExistenceNotDisclosed,
        message: authSignupStartBlockedMessage,
      );
    }
    if (message.contains('confirm') || message.contains('not confirmed')) {
      return const AuthBackendFailure(AuthBackendFailureCode.emailNotVerified);
    }
    if (message.contains('google') || message.contains('apple')) {
      return const AuthBackendFailure(
        AuthBackendFailureCode.providerUnavailable,
      );
    }
    if (signIn ||
        message.contains('invalid') ||
        message.contains('credential') ||
        message.contains('not registered') ||
        message.contains('sign up first') ||
        message.contains('not found')) {
      return const AuthBackendFailure(
        AuthBackendFailureCode.invalidCredentialsNeutral,
      );
    }
    if (passwordReset) {
      return const AuthBackendFailure(
        AuthBackendFailureCode.networkOffline,
        message: authResetRequestRetryableMessage,
      );
    }
    return AuthBackendFailure(
      AuthBackendFailureCode.unknown,
      message: _messageFor(error),
    );
  }

  String _messageFor(Object error) {
    if (error is AuthException) {
      return error.message;
    }
    if (error is SupabaseAuthException) {
      return error.message;
    }
    return error.toString();
  }
}
