import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_backend_contract.dart';

/// Contract for future authentication providers.
abstract interface class AuthRepository {
  /// Returns the current identity.
  ///
  /// Local-first mode returns a local anonymous user and does not require cloud
  /// authentication.
  Future<AppUser?> currentUser();

  /// Placeholder sign-in action for future provider integration.
  Future<AppUser> signIn();

  /// Starts an anonymous session when supported by the auth provider.
  Future<AppUser> signInAnonymously();

  /// Signs in with email and password when supported by the auth provider.
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Creates an email/password account when supported by the auth provider.
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  });

  /// Resends a Supabase email confirmation message when supported.
  Future<void> resendEmailConfirmation({required String email});

  /// Sends a password reset email when supported.
  Future<void> sendPasswordResetEmail({required String email});

  /// Signs in with Google when supported by the auth provider.
  Future<AppUser> signInWithGoogle();

  /// Signs in with Apple when supported by the auth provider.
  Future<AppUser> signInWithApple();

  /// Signs the current user out.
  Future<void> signOut();
}

/// Optional capability for the frozen S02 -> S03 -> S04 staged signup flow.
///
/// Keeping this separate from [AuthRepository] lets legacy/local repositories stay
/// valid while Supabase-backed repositories can advertise OTP signup support.
abstract interface class OtpSignupAuthRepository {
  /// Starts an email OTP signup without collecting a password first.
  Future<void> startEmailOtpSignup({required String email});

  /// Verifies the in-app OTP code and establishes provider auth state if supported.
  Future<EmailOtpVerification> verifyEmailOtp({
    required String email,
    required String code,
  });

  /// Creates or updates the password after OTP verification.
  Future<AppUser> createPasswordAfterOtp({required String password});
}
