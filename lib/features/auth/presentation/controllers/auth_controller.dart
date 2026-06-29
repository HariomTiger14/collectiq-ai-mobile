import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the auth repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(
    supabaseService: ref.watch(supabaseServiceProvider),
  );
});

/// Placeholder auth state for future account support.
class AuthState {
  /// Creates auth state.
  const AuthState({this.user, this.isLoading = false, this.errorMessage});

  /// Current signed-in user, null in local-first guest mode.
  final AppUser? user;

  /// Whether an auth action is running.
  final bool isLoading;

  /// User-safe auth error.
  final String? errorMessage;

  /// Whether a user is signed in.
  bool get isSignedIn => user != null;

  /// Label shown in Settings.
  String get statusLabel => isSignedIn ? 'Signed in' : 'Guest mode';

  /// Creates a copy with updated fields.
  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearErrorMessage = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

/// Coordinates placeholder auth state.
class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repository;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    Future.microtask(loadCurrentUser);
    return const AuthState();
  }

  /// Loads the current user without requiring sign-in.
  Future<void> loadCurrentUser() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final user = await _repository.currentUser();
      state = state.copyWith(
        user: user,
        isLoading: false,
        clearUser: user == null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load account status.',
      );
    }
  }

  /// Placeholder sign-in action for future implementation.
  Future<void> signIn() async {
    return signInAnonymously();
  }

  /// Starts an anonymous session or local guest placeholder.
  Future<void> signInAnonymously() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final user = await _repository.signInAnonymously();
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Sign in is not available yet.',
      );
    }
  }

  /// Email/password foundation for future account screens.
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final user = await _repository.signInWithEmailPassword(
        email: email,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email sign in is not available yet.',
      );
    }
  }

  /// Signs out and returns to guest mode.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      await _repository.signOut();
      state = state.copyWith(isLoading: false, clearUser: true);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to sign out.',
      );
    }
  }
}

/// Provides auth presentation state.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
