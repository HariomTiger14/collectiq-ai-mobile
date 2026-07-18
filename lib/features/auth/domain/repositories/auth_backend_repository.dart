import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_backend_contract.dart';

/// Backend-facing auth contract for the reset Authentication S01-S06 flow.
abstract interface class AuthBackendRepository {
  Future<AuthBackendResult<AppUser?>> currentUser();

  Future<AuthBackendResult<AppUser>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AuthBackendResult<EmailSignupStart>> startEmailSignup({
    required String email,
  });

  Future<AuthBackendResult<EmailOtpVerification>> verifyEmailOtp({
    required String email,
    required String code,
  });

  Future<AuthBackendResult<AppUser>> createPasswordAfterVerification({
    required EmailOtpVerification verification,
    required String password,
  });

  Future<AuthBackendResult<EmailSignupStart>> resendVerificationCode({
    required String email,
  });

  Future<AuthBackendResult<PasswordResetRequestResult>> requestPasswordReset({
    required String email,
  });

  Future<AuthBackendResult<void>> signOut();
}
