import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';

/// Contract for future authentication providers.
abstract interface class AuthRepository {
  /// Returns the currently signed-in user, or null for local-first mode.
  Future<AppUser?> currentUser();

  /// Placeholder sign-in action for future provider integration.
  Future<AppUser> signIn();

  /// Signs the current user out.
  Future<void> signOut();
}
