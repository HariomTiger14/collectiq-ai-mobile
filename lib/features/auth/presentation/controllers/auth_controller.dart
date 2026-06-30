import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
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

  /// Current identity. Local-first mode uses a local anonymous user.
  final AppUser? user;

  /// Whether an auth action is running.
  final bool isLoading;

  /// User-safe auth error.
  final String? errorMessage;

  /// Whether a cloud-backed user is signed in.
  bool get isSignedIn => user != null && user!.isCloudBacked;

  /// Whether the app is running in local anonymous mode.
  bool get isLocalMode => user == null || user!.isLocalOnly;

  /// Current account mode label.
  String get accountModeLabel {
    if (user == null || user!.isLocalOnly) {
      return AuthProviderType.localAnonymous.displayName;
    }

    return user!.provider.displayName;
  }

  /// Label shown in Settings.
  String get statusLabel => isSignedIn ? 'Signed in' : 'Local mode';

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
    } on Object catch (error) {
      debugPrint('[Auth] load current user failed: $error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageForError(error),
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
    } on Object catch (error) {
      debugPrint('[Auth] anonymous sign-in failed: $error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageForError(error),
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
    } on Object catch (error) {
      debugPrint('[Auth] email sign-in failed: $error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageForError(error),
      );
    }
  }

  /// Signs out and returns to guest mode.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      await _repository.signOut();
      final user = await _repository.currentUser();
      state = state.copyWith(
        user: user,
        isLoading: false,
        clearUser: user == null,
      );
    } on Object catch (error) {
      debugPrint('[Auth] sign out failed: $error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _messageForError(error),
      );
    }
  }

  String _messageForError(Object error) {
    if (error is AuthException) {
      return error.message;
    }

    if (error is SupabaseAuthException) {
      return error.message;
    }

    return 'Unable to connect to Supabase Auth.';
  }
}

/// Provides auth presentation state.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
