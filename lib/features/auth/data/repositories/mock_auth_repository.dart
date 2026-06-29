import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';

/// Mock auth repository used until Firebase/Supabase is connected.
class MockAuthRepository implements AuthRepository {
  /// Creates a mock auth repository.
  const MockAuthRepository();

  static const _mockUser = AppUser(
    id: 'mock-user',
    displayName: 'Local Collector',
    email: null,
    isAnonymous: true,
  );

  @override
  Future<AppUser?> currentUser() async {
    return null;
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
    return AppUser(id: 'mock-email-user', displayName: email, email: email);
  }

  @override
  Future<void> signOut() async {}
}
