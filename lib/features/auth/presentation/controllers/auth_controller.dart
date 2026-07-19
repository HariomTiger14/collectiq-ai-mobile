import 'dart:async';

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

/// Auth flow states defined by the CollectIQ authentication specification.
enum AuthFlowStatus {
  signedOut,
  signingUp,
  confirmationRequired,
  signingIn,
  signedIn,
  sessionRestoring,
  sessionExpired,
  signingOut,
  networkError,
  configurationError,
}

class AuthMessages {
  const AuthMessages._();

  static const confirmationRequired =
      'Check your email to confirm your account, then sign in.';
  static const confirmationResent =
      "Your account already exists but hasn't been confirmed. We've sent (or re-sent) the confirmation email. Please confirm your email then sign in.";
  static const confirmationEmailSent =
      'Confirmation email sent. Please check Inbox, Spam, Junk, and Promotions.';
  static const passwordPolicyHelp =
      'Use at least 12 characters with uppercase, lowercase, number, and symbol.';
  static const confirmationEmailSentSignIn =
      'Check your email to confirm your account, then sign in.';
  static const confirmationRateLimited =
      'Too many confirmation requests. Please wait before trying again.';
  static const confirmationMaxAttempts =
      'Too many confirmation emails requested. Please check your inbox or try again later.';
  static const confirmationTestingTip =
      'Tip: for testing, use Gmail aliases like yourname+sit1@gmail.com.';
  static const emailAlreadyConfirmed =
      'Your email is already confirmed. Please sign in.';
  static const emailNotConfirmed =
      'Please confirm your email before signing in.';
  static const invalidCredentials = 'Invalid email or password.';
  static const emailNotRegistered = 'Please sign up first.';
  static const networkFailure =
      'Unable to reach Supabase. Check your internet connection.';
  static const authTimedOut =
      'Auth request timed out. Please check your internet and try again.';
  static const signedIn = 'Signed in successfully.';
  static const configurationInvalid =
      'Supabase configuration is missing or invalid.';
  static const sessionExpired = 'Session expired. Please sign in again.';
  static const passwordResetSent = 'Password reset email sent.';
  static const passwordResetSentWithCooldown =
      'Password reset email sent. Please wait before requesting another.';
  static const passwordResetRateLimited =
      'Too many reset requests. Please wait a few minutes and try again.';
  static const emailConfirmed = 'Email confirmed successfully.';
  static const emailConfirmedSignIn = 'Email confirmed. Please sign in.';
  static const confirmationLinkInvalid =
      'This confirmation link is invalid or expired. Please request a new confirmation email.';
  static const confirmationCallbackFailed =
      'Could not complete email confirmation. Please try again.';
}

/// Minimum password length required for PackLox email authentication.
const authPasswordMinLength = 12;

/// Returns the current PackLox password policy validation message, if any.
String? validateAuthPassword(String password) {
  if (password.isEmpty) {
    return 'Enter a password.';
  }
  if (authPasswordPolicyScore(password) < 5) {
    return AuthMessages.passwordPolicyHelp;
  }
  return null;
}

/// Scores a password against the PackLox policy requirements.
int authPasswordPolicyScore(String password) {
  var value = 0;
  if (password.length >= authPasswordMinLength) value++;
  if (RegExp(r'[a-z]').hasMatch(password)) value++;
  if (RegExp(r'[A-Z]').hasMatch(password)) value++;
  if (RegExp(r'\d').hasMatch(password)) value++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) value++;
  return value;
}

/// Placeholder auth state for future account support.
class AuthState {
  /// Creates auth state.
  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.infoMessage,
    this.status = AuthFlowStatus.sessionRestoring,
    this.pendingConfirmationEmail,
    this.resendCooldownUntil,
    this.resendRateLimitedUntil,
    this.resendAttemptTimestamps = const <DateTime>[],
    this.lastResendStatus = 'none',
    this.resendCooldownSource = 'none',
    this.passwordResetCooldownUntil,
    this.passwordResetRateLimitedUntil,
    this.lastPasswordResetStatus = 'none',
    this.lastPasswordResetRedirectUrl,
    this.passwordResetCooldownSource = 'none',
  });

  /// Current identity. Local-first mode uses a local anonymous user.
  final AppUser? user;

  /// Whether an auth action is running.
  final bool isLoading;

  /// User-safe auth error.
  final String? errorMessage;

  /// User-safe non-error auth status message.
  final String? infoMessage;

  /// Current authentication flow state.
  final AuthFlowStatus status;

  /// Email address awaiting confirmation, if known.
  final String? pendingConfirmationEmail;

  /// Time until normal resend cooldown ends.
  final DateTime? resendCooldownUntil;

  /// Time until rate-limit cooldown ends.
  final DateTime? resendRateLimitedUntil;

  /// Confirmation resend attempt timestamps for this app session.
  final List<DateTime> resendAttemptTimestamps;

  /// Last confirmation resend outcome for safe SIT diagnostics.
  final String lastResendStatus;

  /// Source of the current resend cooldown for safe SIT diagnostics.
  final String resendCooldownSource;

  /// Time until password reset can be requested again.
  final DateTime? passwordResetCooldownUntil;

  /// Time until password reset rate-limit cooldown ends.
  final DateTime? passwordResetRateLimitedUntil;

  /// Last password reset outcome for safe SIT diagnostics.
  final String lastPasswordResetStatus;

  /// Password recovery redirect URL supplied to Supabase.
  final String? lastPasswordResetRedirectUrl;

  /// Source of the current password reset cooldown for safe SIT diagnostics.
  final String passwordResetCooldownSource;

  /// Whether a cloud-backed user is signed in.
  bool get isSignedIn =>
      user != null && user!.isCloudBacked && !user!.isAnonymous;

  /// Whether a Supabase anonymous/dev session is present.
  bool get isAnonymousCloudSession {
    final currentUser = user;
    return currentUser != null &&
        currentUser.isCloudBacked &&
        currentUser.isAnonymous;
  }

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
  String get statusLabel {
    if (isSignedIn) {
      return 'Signed in';
    }
    if (isAnonymousCloudSession) {
      return 'Anonymous dev session';
    }
    return 'Local mode';
  }

  /// Returns the active resend block end time, if any.
  DateTime? resendBlockedUntil(DateTime now) {
    final candidates = [
      resendCooldownUntil,
      resendRateLimitedUntil,
    ].whereType<DateTime>().where((value) => value.isAfter(now)).toList();
    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort();
    return candidates.last;
  }

  /// Whether resend is currently blocked by cooldown or rate limit.
  bool isResendBlocked(DateTime now) => resendBlockedUntil(now) != null;

  /// Human-readable resend countdown label.
  String? resendCountdownLabel(DateTime now) {
    final blockedUntil = resendBlockedUntil(now);
    if (blockedUntil == null) {
      return null;
    }
    final remaining = blockedUntil.difference(now).inSeconds;
    return 'Resend available in ${remaining < 1 ? 1 : remaining}s';
  }

  /// Most recent resend attempt timestamp for safe SIT diagnostics.
  DateTime? get lastResendAttemptedAt {
    if (resendAttemptTimestamps.isEmpty) {
      return null;
    }
    return resendAttemptTimestamps.last;
  }

  /// Remaining normal resend cooldown for safe SIT diagnostics.
  Duration? resendCooldownRemaining(DateTime now) {
    final cooldownUntil = resendCooldownUntil;
    if (cooldownUntil == null || !cooldownUntil.isAfter(now)) {
      return null;
    }
    return cooldownUntil.difference(now);
  }

  /// Remaining Supabase rate-limit cooldown for safe SIT diagnostics.
  Duration? resendRateLimitRemaining(DateTime now) {
    final rateLimitedUntil = resendRateLimitedUntil;
    if (rateLimitedUntil == null || !rateLimitedUntil.isAfter(now)) {
      return null;
    }
    return rateLimitedUntil.difference(now);
  }

  /// Remaining active resend cooldown for safe SIT diagnostics.
  Duration? activeResendCooldownRemaining(DateTime now) {
    final blockedUntil = resendBlockedUntil(now);
    if (blockedUntil == null) {
      return null;
    }
    return blockedUntil.difference(now);
  }

  /// Returns the active password reset block end time, if any.
  DateTime? passwordResetBlockedUntil(DateTime now) {
    final candidates = [
      passwordResetCooldownUntil,
      passwordResetRateLimitedUntil,
    ].whereType<DateTime>().where((value) => value.isAfter(now)).toList();
    if (candidates.isEmpty) {
      return null;
    }
    candidates.sort();
    return candidates.last;
  }

  /// Human-readable password reset countdown label.
  String? passwordResetCountdownLabel(DateTime now) {
    final blockedUntil = passwordResetBlockedUntil(now);
    if (blockedUntil == null) {
      return null;
    }
    final remaining = blockedUntil.difference(now).inSeconds;
    return 'Reset available in ${remaining < 1 ? 1 : remaining}s';
  }

  /// Remaining active password reset cooldown for safe SIT diagnostics.
  Duration? activePasswordResetCooldownRemaining(DateTime now) {
    final blockedUntil = passwordResetBlockedUntil(now);
    if (blockedUntil == null) {
      return null;
    }
    return blockedUntil.difference(now);
  }

  /// Creates a copy with updated fields.
  AuthState copyWith({
    AppUser? user,
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    AuthFlowStatus? status,
    String? pendingConfirmationEmail,
    DateTime? resendCooldownUntil,
    DateTime? resendRateLimitedUntil,
    List<DateTime>? resendAttemptTimestamps,
    String? lastResendStatus,
    String? resendCooldownSource,
    DateTime? passwordResetCooldownUntil,
    DateTime? passwordResetRateLimitedUntil,
    String? lastPasswordResetStatus,
    String? lastPasswordResetRedirectUrl,
    String? passwordResetCooldownSource,
    bool clearUser = false,
    bool clearErrorMessage = false,
    bool clearInfoMessage = false,
    bool clearPendingConfirmationEmail = false,
    bool clearResendCooldownUntil = false,
    bool clearResendRateLimitedUntil = false,
    bool clearResendAttemptTimestamps = false,
    bool clearResendCooldownSource = false,
    bool clearPasswordResetCooldownUntil = false,
    bool clearPasswordResetRateLimitedUntil = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
      status: status ?? this.status,
      pendingConfirmationEmail: clearPendingConfirmationEmail
          ? null
          : pendingConfirmationEmail ?? this.pendingConfirmationEmail,
      resendCooldownUntil: clearResendCooldownUntil
          ? null
          : resendCooldownUntil ?? this.resendCooldownUntil,
      resendRateLimitedUntil: clearResendRateLimitedUntil
          ? null
          : resendRateLimitedUntil ?? this.resendRateLimitedUntil,
      resendAttemptTimestamps: clearResendAttemptTimestamps
          ? const <DateTime>[]
          : resendAttemptTimestamps ?? this.resendAttemptTimestamps,
      lastResendStatus: lastResendStatus ?? this.lastResendStatus,
      resendCooldownSource: clearResendCooldownSource
          ? 'none'
          : resendCooldownSource ?? this.resendCooldownSource,
      passwordResetCooldownUntil: clearPasswordResetCooldownUntil
          ? null
          : passwordResetCooldownUntil ?? this.passwordResetCooldownUntil,
      passwordResetRateLimitedUntil: clearPasswordResetRateLimitedUntil
          ? null
          : passwordResetRateLimitedUntil ?? this.passwordResetRateLimitedUntil,
      lastPasswordResetStatus:
          lastPasswordResetStatus ?? this.lastPasswordResetStatus,
      lastPasswordResetRedirectUrl:
          lastPasswordResetRedirectUrl ?? this.lastPasswordResetRedirectUrl,
      passwordResetCooldownSource:
          passwordResetCooldownSource ?? this.passwordResetCooldownSource,
    );
  }
}

/// Coordinates placeholder auth state.
class AuthController extends Notifier<AuthState> {
  static const resendCooldownDuration = Duration(seconds: 60);
  static const resendRateLimitCooldownDuration = Duration(minutes: 5);
  static const passwordResetCooldownDuration = Duration(seconds: 60);
  static const resendAttemptWindow = Duration(minutes: 15);
  static const maxResendAttemptsPerWindow = 3;
  static const authRequestTimeout = Duration(seconds: 20);

  late AuthRepository _repository;
  var _sessionMutationVersion = 0;

  @override
  AuthState build() {
    _repository = ref.watch(authRepositoryProvider);
    final scheduledRestoreVersion = _sessionMutationVersion;
    Future.microtask(() => _loadCurrentUser(scheduledRestoreVersion));
    return const AuthState();
  }

  /// Loads the current user without requiring sign-in.
  Future<void> loadCurrentUser() {
    return _loadCurrentUser(_sessionMutationVersion);
  }

  Future<void> _loadCurrentUser(int restoreVersion) async {
    state = state.copyWith(
      isLoading: true,
      status: AuthFlowStatus.sessionRestoring,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
    try {
      final user = await _repository.currentUser();
      if (restoreVersion != _sessionMutationVersion) {
        return;
      }
      state = state.copyWith(
        user: user,
        isLoading: false,
        status: user != null && user.isCloudBacked && !user.isAnonymous
            ? AuthFlowStatus.signedIn
            : AuthFlowStatus.signedOut,
        clearUser: user == null,
        clearPendingConfirmationEmail: user != null && user.isCloudBacked,
        clearResendCooldownUntil: user != null && user.isCloudBacked,
        clearResendRateLimitedUntil: user != null && user.isCloudBacked,
      );
    } on Object catch (error) {
      if (restoreVersion != _sessionMutationVersion) {
        return;
      }
      debugPrint('[Auth] load current user failed: $error');
      final message = _messageForError(error);
      state = state.copyWith(
        isLoading: false,
        status: _statusForError(error),
        errorMessage: message,
        clearUser: true,
      );
    }
  }

  /// Placeholder sign-in action for future implementation.
  Future<void> signIn() async {
    return signInAnonymously();
  }

  /// Starts an anonymous session or local guest placeholder.
  Future<void> signInAnonymously() async {
    state = state.copyWith(
      isLoading: true,
      status: AuthFlowStatus.signingIn,
      clearErrorMessage: true,
      clearInfoMessage: true,
      clearPendingConfirmationEmail: true,
    );
    try {
      final user = await _repository.signInAnonymously();
      state = state.copyWith(
        user: user,
        isLoading: false,
        status: AuthFlowStatus.signedOut,
      );
    } on Object catch (error) {
      debugPrint('[Auth] anonymous sign-in failed: $error');
      state = state.copyWith(
        isLoading: false,
        status: _statusForError(error),
        errorMessage: _messageForError(error),
      );
    }
  }

  /// Email/password foundation for future account screens.
  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final validationMessage = _validateEmailPassword(
      email: email,
      password: password,
    );
    if (validationMessage != null) {
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.signedOut,
        errorMessage: validationMessage,
        clearInfoMessage: true,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      status: AuthFlowStatus.signingIn,
      clearErrorMessage: true,
      clearInfoMessage: true,
      clearPendingConfirmationEmail: true,
    );
    try {
      final user = await _withAuthTimeout(
        _repository.signInWithEmailPassword(email: email, password: password),
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        status: AuthFlowStatus.signedIn,
        infoMessage: AuthMessages.signedIn,
        clearPendingConfirmationEmail: true,
        clearResendCooldownUntil: true,
        clearResendRateLimitedUntil: true,
        clearResendCooldownSource: true,
      );
    } on Object catch (error) {
      debugPrint('[Auth] email sign-in failed: $error');
      final status = _statusForError(error);
      state = state.copyWith(
        isLoading: false,
        status: status,
        errorMessage: _messageForError(error),
        pendingConfirmationEmail: status == AuthFlowStatus.confirmationRequired
            ? email.trim()
            : null,
        clearPendingConfirmationEmail:
            status != AuthFlowStatus.confirmationRequired,
        clearUser: true,
      );
    }
  }

  /// Creates an email/password Supabase account when configured.
  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final validationMessage = _validateEmailPassword(
      email: email,
      password: password,
    );
    if (validationMessage != null) {
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.signedOut,
        errorMessage: validationMessage,
        clearInfoMessage: true,
      );
      return;
    }

    final trimmedEmail = email.trim();
    final wasAwaitingConfirmation =
        state.status == AuthFlowStatus.confirmationRequired &&
        state.pendingConfirmationEmail == trimmedEmail;

    state = state.copyWith(
      isLoading: true,
      status: AuthFlowStatus.signingUp,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
    try {
      final user = await _withAuthTimeout(
        _repository.signUpWithEmailPassword(email: email, password: password),
      );
      state = state.copyWith(
        user: user,
        isLoading: false,
        status: AuthFlowStatus.signedIn,
        infoMessage: AuthMessages.signedIn,
        clearPendingConfirmationEmail: true,
        clearResendCooldownUntil: true,
        clearResendRateLimitedUntil: true,
        clearResendCooldownSource: true,
      );
    } on SupabaseEmailConfirmationRequiredException catch (confirmation) {
      debugPrint('[Auth] email sign-up requires confirmation: $confirmation');
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.confirmationRequired,
        clearUser: true,
        clearErrorMessage: true,
        infoMessage: wasAwaitingConfirmation
            ? AuthMessages.confirmationResent
            : AuthMessages.confirmationRequired,
        pendingConfirmationEmail: trimmedEmail,
      );
    } on SupabaseEmailConfirmationSentException catch (confirmation) {
      debugPrint('[Auth] email sign-up sent confirmation: $confirmation');
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.confirmationRequired,
        clearUser: true,
        clearErrorMessage: true,
        infoMessage: AuthMessages.confirmationEmailSentSignIn,
        pendingConfirmationEmail: trimmedEmail,
      );
    } on Object catch (error) {
      debugPrint('[Auth] email sign-up failed: $error');
      state = state.copyWith(
        isLoading: false,
        status: _statusForError(error),
        errorMessage: _messageForError(error),
      );
    }
  }

  /// Resends a Supabase email confirmation message.
  Future<void> resendConfirmationEmail({
    required String email,
    DateTime? now,
  }) async {
    final currentTime = now ?? DateTime.now();
    final validationMessage = _validateEmail(email);
    if (validationMessage != null) {
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.confirmationRequired,
        errorMessage: validationMessage,
        clearInfoMessage: true,
      );
      return;
    }

    final trimmedEmail = email.trim();
    final trimmedAttempts = _recentResendAttempts(currentTime);
    final blockedUntil = state.resendBlockedUntil(currentTime);
    if (blockedUntil != null) {
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.confirmationRequired,
        pendingConfirmationEmail: trimmedEmail,
        resendAttemptTimestamps: trimmedAttempts,
        infoMessage: state.resendCountdownLabel(currentTime),
        clearErrorMessage: true,
      );
      return;
    }
    if (trimmedAttempts.length >= maxResendAttemptsPerWindow) {
      final cooldownUntil = trimmedAttempts.first.add(resendAttemptWindow);
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.confirmationRequired,
        pendingConfirmationEmail: trimmedEmail,
        resendCooldownUntil: cooldownUntil,
        resendAttemptTimestamps: trimmedAttempts,
        lastResendStatus: 'failed',
        resendCooldownSource: 'app-limit',
        errorMessage: AuthMessages.confirmationMaxAttempts,
        clearInfoMessage: true,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      status: AuthFlowStatus.signingUp,
      clearErrorMessage: true,
      clearInfoMessage: true,
      resendAttemptTimestamps: trimmedAttempts,
    );
    try {
      await _repository.resendEmailConfirmation(email: trimmedEmail);
      final updatedAttempts = [...trimmedAttempts, currentTime];
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.confirmationRequired,
        clearUser: true,
        infoMessage: AuthMessages.confirmationEmailSent,
        pendingConfirmationEmail: trimmedEmail,
        resendCooldownUntil: currentTime.add(resendCooldownDuration),
        resendAttemptTimestamps: updatedAttempts,
        lastResendStatus: 'sent',
        resendCooldownSource: 'success',
        clearResendRateLimitedUntil: true,
      );
    } on SupabaseConfirmationRateLimitedException catch (error) {
      debugPrint('[Auth] resend confirmation rate-limited: $error');
      final updatedAttempts = [...trimmedAttempts, currentTime];
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.confirmationRequired,
        errorMessage: AuthMessages.confirmationRateLimited,
        pendingConfirmationEmail: trimmedEmail,
        resendRateLimitedUntil: currentTime.add(error.cooldown),
        resendAttemptTimestamps: updatedAttempts,
        lastResendStatus: 'rate-limited',
        resendCooldownSource: error.cooldownSource,
        clearInfoMessage: true,
      );
    } on Object catch (error) {
      debugPrint('[Auth] resend confirmation failed: $error');
      final message = _messageForError(error);
      final status = message == AuthMessages.confirmationRateLimited
          ? AuthFlowStatus.confirmationRequired
          : _statusForError(error);
      final isRateLimited = message == AuthMessages.confirmationRateLimited;
      state = state.copyWith(
        isLoading: false,
        status: status,
        errorMessage: message,
        pendingConfirmationEmail: trimmedEmail,
        resendRateLimitedUntil: isRateLimited
            ? currentTime.add(resendRateLimitCooldownDuration)
            : null,
        resendAttemptTimestamps: isRateLimited
            ? [...trimmedAttempts, currentTime]
            : trimmedAttempts,
        lastResendStatus: isRateLimited ? 'rate-limited' : 'failed',
        resendCooldownSource: isRateLimited ? 'fallback' : 'none',
        clearInfoMessage: true,
      );
    }
  }

  /// Sends a password reset email through Supabase when configured.
  Future<void> sendPasswordResetEmail({required String email}) async {
    final now = DateTime.now();
    final validationMessage = _validateEmail(email);
    if (validationMessage != null) {
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.signedOut,
        errorMessage: validationMessage,
        clearInfoMessage: true,
      );
      return;
    }

    final trimmedEmail = email.trim();
    final blockedUntil = state.passwordResetBlockedUntil(now);
    if (blockedUntil != null) {
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.signedOut,
        infoMessage: state.passwordResetCountdownLabel(now),
        lastPasswordResetStatus: 'blocked',
        lastPasswordResetRedirectUrl: SupabaseService.passwordResetRedirectUri,
        clearErrorMessage: true,
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      status: AuthFlowStatus.signingIn,
      lastPasswordResetRedirectUrl: SupabaseService.passwordResetRedirectUri,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
    try {
      await _withAuthTimeout(
        _repository.sendPasswordResetEmail(email: trimmedEmail),
      );
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.signedOut,
        infoMessage: AuthMessages.passwordResetSentWithCooldown,
        passwordResetCooldownUntil: now.add(passwordResetCooldownDuration),
        lastPasswordResetStatus: 'sent',
        lastPasswordResetRedirectUrl: SupabaseService.passwordResetRedirectUri,
        passwordResetCooldownSource: 'success',
        clearErrorMessage: true,
      );
    } on SupabasePasswordResetRateLimitedException catch (error) {
      debugPrint('[Auth] password reset rate-limited: $error');
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.signedOut,
        errorMessage: AuthMessages.passwordResetRateLimited,
        passwordResetRateLimitedUntil: now.add(error.cooldown),
        lastPasswordResetStatus: 'rate-limited',
        lastPasswordResetRedirectUrl: SupabaseService.passwordResetRedirectUri,
        passwordResetCooldownSource: error.cooldownSource,
        clearInfoMessage: true,
      );
    } on Object catch (error) {
      debugPrint('[Auth] password reset failed: $error');
      state = state.copyWith(
        isLoading: false,
        status: _statusForError(error),
        errorMessage: _messageForError(error),
        lastPasswordResetStatus: 'failed',
        lastPasswordResetRedirectUrl: SupabaseService.passwordResetRedirectUri,
        clearInfoMessage: true,
      );
    }
  }

  /// Applies an authenticated backend-contract user to the app shell state.
  void applySignedInUser(AppUser user) {
    _sessionMutationVersion += 1;
    state = state.copyWith(
      user: user,
      isLoading: false,
      status: AuthFlowStatus.signedIn,
      infoMessage: AuthMessages.signedIn,
      clearErrorMessage: true,
      clearPendingConfirmationEmail: true,
      clearResendCooldownUntil: true,
      clearResendRateLimitedUntil: true,
      clearResendCooldownSource: true,
      clearPasswordResetCooldownUntil: true,
      clearPasswordResetRateLimitedUntil: true,
    );
  }

  /// Applies a successfully completed email confirmation session.
  void applyEmailConfirmationSession(AppUser user) {
    state = state.copyWith(
      user: user,
      isLoading: false,
      status: AuthFlowStatus.signedIn,
      infoMessage: AuthMessages.emailConfirmed,
      clearErrorMessage: true,
      clearPendingConfirmationEmail: true,
      clearResendCooldownUntil: true,
      clearResendRateLimitedUntil: true,
      clearResendCooldownSource: true,
    );
  }

  /// Applies email confirmation success when Supabase returns no session.
  void applyEmailConfirmationWithoutSession() {
    state = state.copyWith(
      isLoading: false,
      status: AuthFlowStatus.signedOut,
      infoMessage: AuthMessages.emailConfirmedSignIn,
      clearErrorMessage: true,
      clearUser: true,
      clearPendingConfirmationEmail: true,
      clearResendCooldownUntil: true,
      clearResendRateLimitedUntil: true,
      clearResendCooldownSource: true,
    );
  }

  /// Applies a user-safe email confirmation callback error.
  void applyEmailConfirmationError(String message) {
    state = state.copyWith(
      isLoading: false,
      status: AuthFlowStatus.signedOut,
      errorMessage: message,
      clearInfoMessage: true,
      clearUser: true,
    );
  }

  /// Signs out and returns to guest mode.
  Future<void> signOut() async {
    state = state.copyWith(
      isLoading: true,
      status: AuthFlowStatus.signingOut,
      clearErrorMessage: true,
      clearInfoMessage: true,
    );
    try {
      await _repository.signOut();
      state = state.copyWith(
        isLoading: false,
        status: AuthFlowStatus.signedOut,
        clearUser: true,
        clearPendingConfirmationEmail: true,
        clearResendCooldownUntil: true,
        clearResendRateLimitedUntil: true,
        clearResendCooldownSource: true,
      );
    } on Object catch (error) {
      debugPrint('[Auth] sign out failed: $error');
      state = state.copyWith(
        isLoading: false,
        status: _statusForError(error),
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

    if (error is SupabaseConfirmationRateLimitedException) {
      return AuthMessages.confirmationRateLimited;
    }

    if (error is SupabaseEmailConfirmationRequiredException) {
      return AuthMessages.confirmationRequired;
    }

    if (error is SupabaseEmailConfirmationSentException) {
      return AuthMessages.confirmationRequired;
    }

    if (error is SupabaseSessionExpiredException) {
      return AuthMessages.sessionExpired;
    }

    if (error is SupabaseNotConfiguredException) {
      return AuthMessages.configurationInvalid;
    }

    if (error is TimeoutException) {
      return AuthMessages.authTimedOut;
    }

    return 'Supabase Auth returned an unexpected response.';
  }

  AuthFlowStatus _statusForError(Object error) {
    final message = _messageForError(error);
    if (error is SupabaseNotConfiguredException) {
      return AuthFlowStatus.configurationError;
    }
    if (error is SupabaseSessionExpiredException) {
      return AuthFlowStatus.sessionExpired;
    }
    if (error is SupabaseEmailConfirmationRequiredException ||
        message == AuthMessages.emailNotConfirmed) {
      return AuthFlowStatus.confirmationRequired;
    }
    if (message == AuthMessages.networkFailure) {
      return AuthFlowStatus.networkError;
    }
    return AuthFlowStatus.signedOut;
  }

  Future<T> _withAuthTimeout<T>(Future<T> future) {
    return future.timeout(
      authRequestTimeout,
      onTimeout: () => throw TimeoutException(AuthMessages.authTimedOut),
    );
  }

  String? _validateEmailPassword({
    required String email,
    required String password,
  }) {
    final emailError = _validateEmail(email);
    if (emailError != null) {
      return emailError;
    }
    return validateAuthPassword(password);
  }

  String? _validateEmail(String email) {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      return 'Enter an email address.';
    }
    if (!_emailPattern.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  List<DateTime> _recentResendAttempts(DateTime now) {
    final oldestAllowed = now.subtract(resendAttemptWindow);
    return state.resendAttemptTimestamps
        .where((timestamp) => timestamp.isAfter(oldestAllowed))
        .toList(growable: false);
  }
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Provides auth presentation state.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
