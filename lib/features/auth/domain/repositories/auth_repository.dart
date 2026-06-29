import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';

/// Contract for future authentication providers.
abstract interface class AuthRepository {
  /// Returns the currently signed-in user, or null for local-first mode.
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

  /// Signs the current user out.
  Future<void> signOut();
}
