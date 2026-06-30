import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';

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

  /// Signs in with Google when supported by the auth provider.
  Future<AppUser> signInWithGoogle();

  /// Signs in with Apple when supported by the auth provider.
  Future<AppUser> signInWithApple();

  /// Signs the current user out.
  Future<void> signOut();
}
