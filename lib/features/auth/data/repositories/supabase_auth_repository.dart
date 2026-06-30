import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';

class SupabaseAuthRepository implements AuthRepository {
  const SupabaseAuthRepository({
    required this.supabaseService,
    this.fallbackRepository = const MockAuthRepository(),
  });

  final SupabaseAuthGateway supabaseService;
  final AuthRepository fallbackRepository;

  @override
  Future<AppUser?> currentUser() async {
    if (!supabaseService.isConfigured) {
      debugPrint('[Auth] Supabase not configured; current user is guest');
      return fallbackRepository.currentUser();
    }

    debugPrint('[Auth] loading Supabase current user');
    final session = await supabaseService.ensureAnonymousSession();
    debugPrint('[Auth] current Supabase user id: ${session.userId}');
    return _userFromSession(session);
  }

  @override
  Future<AppUser> signIn() {
    return signInAnonymously();
  }

  @override
  Future<AppUser> signInAnonymously() async {
    if (!supabaseService.isConfigured) {
      debugPrint('[Auth] Supabase not configured; using local guest sign-in');
      return fallbackRepository.signInAnonymously();
    }

    debugPrint('[Auth] starting Supabase anonymous sign-in');
    final session = await supabaseService.signInAnonymously();
    debugPrint('[Auth] Supabase anonymous user id: ${session.userId}');
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
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    if (!supabaseService.isConfigured) {
      return fallbackRepository.signUpWithEmailPassword(
        email: email,
        password: password,
      );
    }

    final session = await supabaseService.signUpWithPassword(
      email: email,
      password: password,
    );
    return _userFromSession(session);
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw const AuthException(
      'Google sign-in is coming soon. Local mode remains available.',
    );
  }

  @override
  Future<AppUser> signInWithApple() {
    throw const AuthException(
      'Apple sign-in is coming soon. Local mode remains available.',
    );
  }

  @override
  Future<void> signOut() async {
    if (!supabaseService.isConfigured) {
      return fallbackRepository.signOut();
    }

    final session = await supabaseService.currentSession();
    if (session == null || session.accessToken.isEmpty) {
      return;
    }

    await supabaseService.signOut(session.accessToken);
  }

  AppUser _userFromSession(SupabaseAuthSession session) {
    return AppUser(
      id: session.userId,
      displayName: session.displayName,
      email: session.email,
      isAnonymous: session.isAnonymous,
      isLocalOnly: false,
      provider: session.isAnonymous
          ? AuthProviderType.supabaseAnonymous
          : AuthProviderType.emailPassword,
    );
  }
}
