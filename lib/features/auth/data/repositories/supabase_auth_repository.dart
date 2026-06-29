import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository({
    required this.supabaseService,
    this.fallbackRepository = const MockAuthRepository(),
  });

  final SupabaseService supabaseService;
  final AuthRepository fallbackRepository;

  @override
  Future<AppUser?> currentUser() async {
    if (!supabaseService.isConfigured) {
      return null;
    }

    // Session persistence will be added when real auth screens are enabled.
    return null;
  }

  @override
  Future<AppUser> signIn() {
    return signInAnonymously();
  }

  @override
  Future<AppUser> signInAnonymously() async {
    if (!supabaseService.isConfigured) {
      return fallbackRepository.signInAnonymously();
    }

    final session = await supabaseService.signInAnonymously();
    return _userFromSession(session);
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!supabaseService.isConfigured) {
      return fallbackRepository.signInWithEmailPassword(
        email: email,
        password: password,
      );
    }

    final session = await supabaseService.signInWithPassword(
      email: email,
      password: password,
    );
    return _userFromSession(session);
  }

  @override
  Future<void> signOut() async {
    if (!supabaseService.isConfigured) {
      return fallbackRepository.signOut();
    }

    // Access-token persistence will be added with real account screens.
  }

  AppUser _userFromSession(SupabaseAuthSession session) {
    return AppUser(
      id: session.userId,
      displayName: session.displayName,
      email: session.email,
      isAnonymous: session.isAnonymous,
    );
  }
}
