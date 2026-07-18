import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_backend_contract.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_backend_repository.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';

/// Adapter from the existing auth repository to the reset backend contract.
///
/// S02-S06 UI is not wired to this adapter yet. Unsupported OTP/password-finalize
/// operations intentionally return capability gaps until the Supabase path is
/// implemented.
class AuthRepositoryBackendAdapter implements AuthBackendRepository {
  const AuthRepositoryBackendAdapter({required this.repository});

  final AuthRepository repository;

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
    return const AuthBackendResult.failure(
      AuthBackendFailure(
        AuthBackendFailureCode.capabilityUnavailable,
        message:
            'Mobile Supabase OTP signup is not implemented in this adapter yet.',
      ),
    );
  }

  @override
  Future<AuthBackendResult<EmailOtpVerification>> verifyEmailOtp({
    required String email,
    required String code,
  }) async {
    return const AuthBackendResult.failure(
      AuthBackendFailure(
        AuthBackendFailureCode.capabilityUnavailable,
        message: 'Mobile Supabase OTP verification is not implemented yet.',
      ),
    );
  }

  @override
  Future<AuthBackendResult<AppUser>> createPasswordAfterVerification({
    required EmailOtpVerification verification,
    required String password,
  }) async {
    return const AuthBackendResult.failure(
      AuthBackendFailure(
        AuthBackendFailureCode.capabilityUnavailable,
        message:
            'Post-OTP password creation requires a Supabase implementation decision.',
      ),
    );
  }

  @override
  Future<AuthBackendResult<EmailSignupStart>> resendVerificationCode({
    required String email,
  }) async {
    try {
      await repository.resendEmailConfirmation(email: email);
      return AuthBackendResult.success(EmailSignupStart(email: email));
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
      final failure = _failureFor(error);
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

  AuthBackendFailure _failureFor(Object error, {bool signIn = false}) {
    final message = _messageFor(error).toLowerCase();
    if (error is SupabaseNotConfiguredException) {
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
