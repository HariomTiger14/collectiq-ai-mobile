import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';

/// Mock auth repository used when Supabase is not configured.
class MockAuthRepository implements AuthRepository {
  /// Creates a mock auth repository.
  const MockAuthRepository();

  static const _mockUser = AppUser(
    id: 'local-anonymous-user',
    displayName: 'Local Collector',
    email: null,
    isAnonymous: true,
    isLocalOnly: true,
    provider: AuthProviderType.localAnonymous,
  );

  @override
  Future<AppUser?> currentUser() async {
    return _mockUser;
  }

  @override
  Future<AppUser> signIn() async {
    return _mockUser;
  }

  @override
  Future<AppUser> signInAnonymously() async {
    return _mockUser;
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    throw const AuthException(
      'Email/password sign-in requires Supabase configuration. Local mode remains available.',
    );
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    throw const AuthException(
      'Email/password sign-up requires Supabase configuration. Local mode remains available.',
    );
  }

  @override
  Future<void> resendEmailConfirmation({required String email}) async {
    throw const AuthException(
      'Email confirmation requires Supabase configuration. Local mode remains available.',
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    throw const AuthException(
      'Password reset requires Supabase configuration. Local mode remains available.',
    );
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    throw const AuthException(
      'Google sign-in is coming soon. Local mode remains available.',
    );
  }

  @override
  Future<AppUser> signInWithApple() async {
    throw const AuthException(
      'Apple sign-in is coming soon. Local mode remains available.',
    );
  }

  @override
  Future<void> signOut() async {}
}
