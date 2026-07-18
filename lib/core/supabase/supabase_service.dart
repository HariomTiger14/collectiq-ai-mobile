import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_auth_response_normalizer.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final supabaseAuthAttemptMetadataProvider =
    NotifierProvider<
      SupabaseAuthAttemptMetadataController,
      SupabaseAuthAttemptMetadata?
    >(SupabaseAuthAttemptMetadataController.new);

class SupabaseAuthAttemptMetadataController
    extends Notifier<SupabaseAuthAttemptMetadata?> {
  @override
  SupabaseAuthAttemptMetadata? build() => null;

  void record(SupabaseAuthAttemptMetadata metadata) {
    state = metadata;
  }
}

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService.instance(
    config: ref.watch(supabaseConfigProvider),
    onAuthAttempt: (metadata) {
      ref.read(supabaseAuthAttemptMetadataProvider.notifier).record(metadata);
    },
  );
});

abstract interface class SupabaseAuthGateway {
  bool get isConfigured;

  Future<SupabaseAuthSession?> currentSession();

  Future<SupabaseAuthSession> ensureAnonymousSession();

  Future<SupabaseAuthSession> signInAnonymously();

  Future<SupabaseAuthSession> signInWithPassword({
    required String email,
    required String password,
  });

  Future<SupabaseAuthSession> signUpWithPassword({
    required String email,
    required String password,
  });

  Future<void> resendEmailConfirmation({required String email});

  Future<void> resetPasswordForEmail({required String email});

  Future<SupabaseAuthSession> completeAuthCallback({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> signOut(String accessToken);
}

abstract interface class SupabaseOtpSignupGateway {
  bool get isConfigured;

  Future<void> startEmailOtpSignup({required String email});

  Future<SupabaseAuthSession> verifyEmailOtp({
    required String email,
    required String token,
  });

  Future<SupabaseAuthSession> createPasswordAfterOtp({
    required String password,
  });
}

abstract interface class SupabaseDataGateway implements SupabaseAuthGateway {
  SupabaseConfig get config;

  Future<Response<T>> authenticatedGetWithSession<T>(
    String path, {
    required SupabaseAuthSession session,
    Map<String, dynamic>? queryParameters,
  });

  Future<Response<T>> authenticatedPostWithSession<T>(
    String path, {
    required SupabaseAuthSession session,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  });
}

class SupabaseService implements SupabaseDataGateway, SupabaseOtpSignupGateway {
  SupabaseService._(this.config, this._onAuthAttempt)
    : _dio = Dio(
        BaseOptions(
          baseUrl: config.url,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (config.anonKey.isNotEmpty) 'apikey': config.anonKey,
            if (config.anonKey.isNotEmpty)
              'Authorization': 'Bearer ${config.anonKey}',
          },
        ),
      ) {
    _logInitialization();
  }

  static SupabaseService? _instance;
  static const _sessionKey = 'supabase_auth_session';
  static const passwordResetRedirectUri =
      'https://packlox.com/auth/reset-password';

  @override
  final SupabaseConfig config;
  final Dio _dio;
  void Function(SupabaseAuthAttemptMetadata metadata)? _onAuthAttempt;
  SupabaseAuthSession? _cachedSession;

  static SupabaseService instance({
    required SupabaseConfig config,
    void Function(SupabaseAuthAttemptMetadata metadata)? onAuthAttempt,
  }) {
    final current = _instance;
    if (current != null &&
        current.config.url == config.url &&
        current.config.anonKey == config.anonKey &&
        current.config.isEnabled == config.isEnabled) {
      current._onAuthAttempt = onAuthAttempt;
      return current;
    }

    _instance = SupabaseService._(config, onAuthAttempt);
    return _instance!;
  }

  @override
  bool get isConfigured => config.isConfigured;

  @override
  Future<SupabaseAuthSession?> currentSession() async {
    if (!isConfigured) {
      debugPrint('[Supabase] current session skipped: not configured');
      return null;
    }

    final cachedSession = _cachedSession;
    if (_isSessionUsableForCurrentProject(cachedSession)) {
      debugPrint(
        '[Supabase] current user id from memory: ${cachedSession!.userId}',
      );
      return cachedSession;
    }

    final preferences = await SharedPreferences.getInstance();
    final encodedSession = preferences.getString(_sessionKey);
    if (encodedSession == null || encodedSession.isEmpty) {
      debugPrint('[Supabase] auth session exists: no');
      return null;
    }
    debugPrint('[Supabase] auth session exists: yes');

    final session = SupabaseAuthSession.fromJsonString(encodedSession);
    if (!_isSessionUsableForCurrentProject(session)) {
      debugPrint(
        '[Supabase] cached session ignored: project URL changed or '
        'session is incomplete',
      );
      await clearSession();
      return null;
    }

    final isValid = await _validateSessionForRestore(session);
    if (!isValid) {
      debugPrint('[Supabase] cached session expired or invalid; clearing');
      await clearSession();
      throw const SupabaseSessionExpiredException();
    }

    _cachedSession = session;
    debugPrint('[Supabase] current user id from storage: ${session.userId}');
    return session;
  }

  @override
  Future<SupabaseAuthSession> ensureAnonymousSession() async {
    final session = await currentSession();
    if (session != null && session.accessToken.isNotEmpty) {
      final isValid = await _validateSession(session);
      if (!isValid) {
        debugPrint(
          '[Supabase] cached session invalid; clearing and signing in again',
        );
        await clearSession();
        return signInAnonymously();
      }

      return session;
    }

    return signInAnonymously();
  }

  @override
  Future<SupabaseAuthSession> signInAnonymously() async {
    _ensureConfigured();
    debugPrint('[Supabase] anonymous sign-in starting');
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/v1/signup',
        data: const {
          'data': {'auth_mode': 'anonymous'},
        },
      );

      final session = SupabaseAuthSession.fromJson(
        response.data ?? {},
        projectUrl: config.url,
      );
      _ensureValidSession(session);
      await _saveSession(session);
      debugPrint(
        '[Supabase] anonymous sign-in success. user id: ${session.userId}',
      );
      return session;
    } on DioException catch (error) {
      logDioException(error, payload: const {'data': '<metadata>'});
      final message = _authFailureMessage(error);
      debugPrint('[Supabase] anonymous sign-in failed: $message');
      throw SupabaseAuthException(message);
    } on FormatException catch (error) {
      debugPrint('[Supabase] anonymous sign-in invalid response: $error');
      throw const SupabaseAuthException(
        'Supabase returned an invalid anonymous auth response.',
      );
    }
  }

  @override
  Future<SupabaseAuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/auth/v1/token',
        queryParameters: const {'grant_type': 'password'},
        data: {'email': email, 'password': password},
      );
    } on DioException catch (error) {
      logDioException(error, payload: const {'email': '', 'password': ''});
      final normalized = _normalizeException(
        action: SupabaseAuthAction.signIn,
        error: error,
      );
      _throwForNormalizedResult(normalized);
    }

    final normalized = _normalizeResponse(
      action: SupabaseAuthAction.signIn,
      response: response,
    );
    if (normalized.status != SupabaseAuthNormalizedStatus.signedIn) {
      _throwForNormalizedResult(normalized);
    }
    final session = SupabaseAuthSession.fromJson(
      _mapBody(response.data),
      projectUrl: config.url,
    );
    _ensureValidSession(session);
    await _saveSession(session);
    return session;
  }

  @override
  Future<SupabaseAuthSession> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    _ensureConfigured();
    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/auth/v1/signup',
        data: {
          'email': email,
          'password': password,
          'data': {'display_name': email},
        },
      );
    } on DioException catch (error) {
      logDioException(error, payload: const {'email': '', 'password': ''});
      final normalized = _normalizeException(
        action: SupabaseAuthAction.signUp,
        error: error,
      );
      _throwForNormalizedResult(normalized);
    }

    final normalized = _normalizeResponse(
      action: SupabaseAuthAction.signUp,
      response: response,
    );
    if (normalized.status != SupabaseAuthNormalizedStatus.signedIn) {
      _throwForNormalizedResult(normalized);
    }

    final session = SupabaseAuthSession.fromJson(
      _mapBody(response.data),
      projectUrl: config.url,
    );
    _ensureValidSession(session);
    await _saveSession(session);
    return session;
  }

  @override
  Future<void> startEmailOtpSignup({required String email}) async {
    _ensureConfigured();
    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/auth/v1/otp',
        data: {
          'email': email,
          'create_user': true,
          'data': {'display_name': email},
        },
      );
    } on DioException catch (error) {
      logDioException(error, payload: const {'email': ''});
      final normalized = _normalizeException(
        action: SupabaseAuthAction.otpSignupStart,
        error: error,
      );
      _throwForNormalizedResult(normalized, confirmationOnly: true);
    }

    final normalized = _normalizeResponse(
      action: SupabaseAuthAction.otpSignupStart,
      response: response,
    );
    if (normalized.status != SupabaseAuthNormalizedStatus.otpSent) {
      _throwForNormalizedResult(normalized, confirmationOnly: true);
    }
  }

  @override
  Future<SupabaseAuthSession> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    _ensureConfigured();
    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/auth/v1/verify',
        data: {'email': email, 'token': token, 'type': 'email'},
      );
    } on DioException catch (error) {
      logDioException(error, payload: const {'email': '', 'token': ''});
      final normalized = _normalizeException(
        action: SupabaseAuthAction.otpVerify,
        error: error,
      );
      _throwForNormalizedResult(normalized);
    }

    final normalized = _normalizeResponse(
      action: SupabaseAuthAction.otpVerify,
      response: response,
    );
    if (normalized.status != SupabaseAuthNormalizedStatus.otpVerified) {
      _throwForNormalizedResult(normalized);
    }

    final session = SupabaseAuthSession.fromJson(
      _mapBody(response.data),
      projectUrl: config.url,
    );
    _ensureValidSession(session);
    await _saveSession(session);
    return session;
  }

  @override
  Future<SupabaseAuthSession> createPasswordAfterOtp({
    required String password,
  }) async {
    _ensureConfigured();
    final session = await currentSession();
    if (session == null || session.accessToken.isEmpty) {
      throw const SupabaseAuthException(
        'Verified auth session is required before creating a password.',
      );
    }

    late final Response<dynamic> response;
    try {
      response = await _dio.put<dynamic>(
        '/auth/v1/user',
        data: {'password': password},
        options: _authOptions(session),
      );
    } on DioException catch (error) {
      logDioException(error, payload: const {'password': ''});
      final normalized = _normalizeException(
        action: SupabaseAuthAction.passwordUpdate,
        error: error,
      );
      _throwForNormalizedResult(normalized);
    }

    final normalized = _normalizeResponse(
      action: SupabaseAuthAction.passwordUpdate,
      response: response,
    );
    if (normalized.status != SupabaseAuthNormalizedStatus.passwordUpdated) {
      _throwForNormalizedResult(normalized);
    }

    final body = _mapBody(response.data);
    final userBody = body['user'] is Map<String, dynamic>
        ? body['user'] as Map<String, dynamic>
        : body;
    final updatedSession = SupabaseAuthSession.fromJson({
      'access_token': session.accessToken,
      'user': userBody,
    }, projectUrl: config.url);
    _ensureValidSession(updatedSession);
    await _saveSession(updatedSession);
    return updatedSession;
  }

  @override
  Future<void> resendEmailConfirmation({required String email}) async {
    _ensureConfigured();
    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/auth/v1/resend',
        data: {'type': 'signup', 'email': email},
      );
    } on DioException catch (error) {
      logDioException(error, payload: const {'type': 'signup', 'email': ''});
      final normalized = _normalizeException(
        action: SupabaseAuthAction.resendConfirmation,
        error: error,
      );
      _throwForNormalizedResult(normalized, confirmationOnly: true);
    }

    final normalized = _normalizeResponse(
      action: SupabaseAuthAction.resendConfirmation,
      response: response,
    );
    if (normalized.status !=
        SupabaseAuthNormalizedStatus.confirmationEmailSent) {
      _throwForNormalizedResult(normalized, confirmationOnly: true);
    }
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    _ensureConfigured();
    late final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        '/auth/v1/recover',
        queryParameters: const {'redirect_to': passwordResetRedirectUri},
        data: {
          'email': email,
          'redirect_to': passwordResetRedirectUri,
          'redirectTo': passwordResetRedirectUri,
        },
      );
    } on DioException catch (error) {
      logDioException(error, payload: const {'email': ''});
      final normalized = _normalizeException(
        action: SupabaseAuthAction.passwordReset,
        error: error,
      );
      _throwForNormalizedResult(normalized);
    }

    final normalized = _normalizeResponse(
      action: SupabaseAuthAction.passwordReset,
      response: response,
    );
    if (normalized.status != SupabaseAuthNormalizedStatus.passwordResetSent) {
      _throwForNormalizedResult(normalized);
    }
  }

  @override
  Future<SupabaseAuthSession> completeAuthCallback({
    required String accessToken,
    required String refreshToken,
  }) async {
    _ensureConfigured();
    if (accessToken.trim().isEmpty || refreshToken.trim().isEmpty) {
      throw const SupabaseAuthException(
        'Could not complete email confirmation. Please try again.',
      );
    }

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/v1/user',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final session = SupabaseAuthSession.fromJson({
        'access_token': accessToken,
        'user': response.data ?? const <String, dynamic>{},
      }, projectUrl: config.url);
      _ensureValidSession(session);
      await _saveSession(session);
      return session;
    } on DioException catch (error) {
      logDioException(error);
      throw SupabaseAuthException(_authFailureMessage(error));
    } on FormatException {
      throw const SupabaseAuthException(
        'Could not complete email confirmation. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut(String accessToken) async {
    _ensureConfigured();
    try {
      await _dio.post<void>(
        '/auth/v1/logout',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (error) {
      logDioException(error);
      rethrow;
    }
    await clearSession();
  }

  Future<void> clearSession() async {
    _cachedSession = null;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_sessionKey);
  }

  Future<Response<T>> authenticatedGet<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final session = await ensureAnonymousSession();
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _authOptions(session),
      );
    } on DioException catch (error) {
      logDioException(error);
      rethrow;
    }
  }

  @override
  Future<Response<T>> authenticatedGetWithSession<T>(
    String path, {
    required SupabaseAuthSession session,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _authOptions(session),
      );
    } on DioException catch (error) {
      logDioException(error);
      rethrow;
    }
  }

  Future<Response<T>> authenticatedPost<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final session = await ensureAnonymousSession();
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeAuthOptions(session, options),
      );
    } on DioException catch (error) {
      logDioException(error, payload: data);
      rethrow;
    }
  }

  @override
  Future<Response<T>> authenticatedPostWithSession<T>(
    String path, {
    required SupabaseAuthSession session,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeAuthOptions(session, options),
      );
    } on DioException catch (error) {
      logDioException(error, payload: data);
      rethrow;
    }
  }

  Future<void> _saveSession(SupabaseAuthSession session) async {
    _cachedSession = session;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_sessionKey, session.toJsonString());
  }

  void _logInitialization() {
    if (!config.isEnabled) {
      debugPrint('[Supabase] initialization skipped: disabled');
      return;
    }

    if (!config.isConfigured) {
      debugPrint(
        '[Supabase] initialization incomplete. URL configured: '
        '${config.hasUrl}, anon key configured: ${config.hasAnonKey}',
      );
      return;
    }

    debugPrint('[Supabase] initialization success');
  }

  bool _isSessionUsableForCurrentProject(SupabaseAuthSession? session) {
    if (session == null ||
        session.accessToken.isEmpty ||
        session.userId.isEmpty ||
        session.projectUrl.isEmpty) {
      return false;
    }

    return session.projectUrl == config.url;
  }

  void _ensureValidSession(SupabaseAuthSession session) {
    if (session.accessToken.isEmpty || session.userId.isEmpty) {
      throw const FormatException('Missing access token or user id.');
    }
  }

  Future<bool> _validateSession(SupabaseAuthSession session) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/v1/user',
        options: _authOptions(session),
      );
      final userId = response.data?['id'] as String?;
      final isValid = userId == session.userId;
      debugPrint('[Supabase] cached session validation success: $isValid');
      return isValid;
    } on DioException catch (error) {
      logDioException(error);
      debugPrint(
        '[Supabase] cached session validation failed: '
        '${_authFailureMessage(error)}',
      );
      return false;
    }
  }

  Future<bool> _validateSessionForRestore(SupabaseAuthSession session) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/auth/v1/user',
        options: _authOptions(session),
      );
      final userId = response.data?['id'] as String?;
      final isValid = userId == session.userId;
      debugPrint('[Supabase] restore session validation success: $isValid');
      return isValid;
    } on DioException catch (error) {
      logDioException(error);
      if (error.response?.statusCode == 401 ||
          error.response?.statusCode == 403) {
        return false;
      }

      throw SupabaseAuthException(_authFailureMessage(error));
    }
  }

  String _authFailureMessage(DioException error) {
    return authFailureMessageForTesting(error);
  }

  SupabaseAuthNormalizedResult _normalizeResponse({
    required SupabaseAuthAction action,
    required Response<dynamic> response,
  }) {
    final normalized = SupabaseAuthResponseNormalizer.normalizeResponse(
      action: action,
      statusCode: response.statusCode,
      body: response.data,
      headers: response.headers,
    );
    _recordAuthAttempt(normalized.metadata);
    _logAuthResponseDiagnostics(normalized.metadata);
    return normalized;
  }

  SupabaseAuthNormalizedResult _normalizeException({
    required SupabaseAuthAction action,
    required DioException error,
  }) {
    final normalized = SupabaseAuthResponseNormalizer.normalizeException(
      action: action,
      error: error,
    );
    _recordAuthAttempt(normalized.metadata);
    _logAuthResponseDiagnostics(normalized.metadata);
    return normalized;
  }

  Never _throwForNormalizedResult(
    SupabaseAuthNormalizedResult normalized, {
    bool confirmationOnly = false,
  }) {
    switch (normalized.status) {
      case SupabaseAuthNormalizedStatus.confirmationRequired:
        throw const SupabaseEmailConfirmationRequiredException();
      case SupabaseAuthNormalizedStatus.confirmationEmailSent:
        throw const SupabaseEmailConfirmationSentException();
      case SupabaseAuthNormalizedStatus.passwordResetSent:
        throw const SupabaseAuthException('Password reset email sent.');
      case SupabaseAuthNormalizedStatus.emailNotConfirmed:
        throw const SupabaseAuthException(
          'Please confirm your email before signing in.',
        );
      case SupabaseAuthNormalizedStatus.rateLimited:
        if (normalized.metadata.action == SupabaseAuthAction.passwordReset) {
          throw SupabasePasswordResetRateLimitedException(
            cooldown: normalized.retryAfter ?? const Duration(minutes: 5),
            cooldownSource: normalized.cooldownSource,
          );
        }
        if (confirmationOnly) {
          throw SupabaseConfirmationRateLimitedException(
            cooldown: normalized.retryAfter ?? const Duration(minutes: 5),
            cooldownSource: normalized.cooldownSource,
          );
        }
        throw const SupabaseAuthException(
          'Too many auth requests. Wait a moment and try again.',
        );
      case SupabaseAuthNormalizedStatus.otpSent:
      case SupabaseAuthNormalizedStatus.otpVerified:
      case SupabaseAuthNormalizedStatus.passwordUpdated:
        throw const SupabaseAuthException(
          'Supabase Auth request completed unexpectedly.',
        );
      case SupabaseAuthNormalizedStatus.invalidCredentials:
      case SupabaseAuthNormalizedStatus.emailNotRegistered:
      case SupabaseAuthNormalizedStatus.alreadyRegistered:
      case SupabaseAuthNormalizedStatus.weakPassword:
      case SupabaseAuthNormalizedStatus.configMissing:
      case SupabaseAuthNormalizedStatus.networkFailure:
      case SupabaseAuthNormalizedStatus.expiredSession:
      case SupabaseAuthNormalizedStatus.temporaryFailure:
      case SupabaseAuthNormalizedStatus.unknownFailure:
        throw SupabaseAuthException(
          SupabaseAuthResponseNormalizer.messageFor(normalized.status),
        );
      case SupabaseAuthNormalizedStatus.signedIn:
      case SupabaseAuthNormalizedStatus.signedOut:
        throw const SupabaseAuthException(
          'Supabase Auth request failed. Try again or check Supabase Auth settings.',
        );
    }
  }

  void _recordAuthAttempt(SupabaseAuthAttemptMetadata metadata) {
    _onAuthAttempt?.call(metadata);
  }

  void _logAuthResponseDiagnostics(SupabaseAuthAttemptMetadata metadata) {
    if (!kDebugMode || !config.isEnabled) {
      return;
    }

    debugPrint('[Supabase Auth] action: ${metadata.actionLabel}');
    debugPrint('[Supabase Auth] status: ${metadata.httpStatus ?? '<none>'}');
    debugPrint('[Supabase Auth] content-type: ${metadata.contentType}');
    debugPrint('[Supabase Auth] body.type: ${metadata.bodyType}');
    debugPrint('[Supabase Auth] response.keys: ${metadata.keys}');
    debugPrint('[Supabase Auth] normalized: ${metadata.statusLabel}');
    debugPrint('[Supabase Auth] user.exists: ${metadata.hasUser}');
    debugPrint('[Supabase Auth] session.exists: ${metadata.hasSession}');
    debugPrint('[Supabase Auth] id.exists: ${metadata.hasDirectId}');
    debugPrint('[Supabase Auth] email.exists: ${metadata.hasDirectEmail}');
    debugPrint('[Supabase Auth] identities.exists: ${metadata.hasIdentities}');
    debugPrint(
      '[Supabase Auth] confirmation_sent_at.exists: '
      '${metadata.hasConfirmationSentAt}',
    );
    debugPrint('[Supabase Auth] error.code.exists: ${metadata.hasErrorCode}');
    debugPrint(
      '[Supabase Auth] error.message.exists: ${metadata.hasErrorMessage}',
    );
  }

  @visibleForTesting
  static bool isEmailConfirmationSignUpResponseForTesting({
    required int? statusCode,
    required Map<String, dynamic>? data,
  }) {
    final normalized = SupabaseAuthResponseNormalizer.normalizeResponse(
      action: SupabaseAuthAction.signUp,
      statusCode: statusCode,
      body: data,
    );
    return normalized.status ==
        SupabaseAuthNormalizedStatus.confirmationRequired;
  }

  @visibleForTesting
  static bool isEmptySuccessfulSignUpResponseForTesting({
    required int? statusCode,
    required Map<String, dynamic>? data,
  }) {
    final normalized = SupabaseAuthResponseNormalizer.normalizeResponse(
      action: SupabaseAuthAction.signUp,
      statusCode: statusCode,
      body: data,
    );
    return normalized.status ==
            SupabaseAuthNormalizedStatus.confirmationRequired &&
        (data == null || data.isEmpty);
  }

  @visibleForTesting
  static String authFailureMessageForTesting(DioException error) {
    final normalized = SupabaseAuthResponseNormalizer.normalizeException(
      action: SupabaseAuthAction.signIn,
      error: error,
    );
    return SupabaseAuthResponseNormalizer.messageFor(normalized.status);
  }

  @visibleForTesting
  static String confirmationFailureMessageForTesting(DioException error) {
    final normalized = SupabaseAuthResponseNormalizer.normalizeException(
      action: SupabaseAuthAction.resendConfirmation,
      error: error,
    );
    if (normalized.status == SupabaseAuthNormalizedStatus.rateLimited) {
      return 'Too many confirmation requests. Please wait before trying again.';
    }

    final responseData = error.response?.data;
    final serverMessage = _serverErrorMessage(responseData);
    if (serverMessage != null && serverMessage.isNotEmpty) {
      final normalized = serverMessage.toLowerCase();
      if (normalized.contains('already confirmed') ||
          normalized.contains('email already confirmed') ||
          normalized.contains('user already confirmed')) {
        return 'Your email is already confirmed. Please sign in.';
      }
      if (normalized.contains('invalid email') ||
          normalized.contains('email address is invalid')) {
        return 'Please enter a valid email address.';
      }
      if (normalized.contains('no api key found') ||
          normalized.contains('no api key') ||
          normalized.contains('missing api key')) {
        return 'Supabase anon key is missing from SIT config.';
      }
      return serverMessage;
    }

    return SupabaseAuthResponseNormalizer.messageFor(normalized.status);
  }

  @visibleForTesting
  static Duration? retryAfterDurationForTesting(Headers? headers) {
    return SupabaseAuthResponseNormalizer.retryAfterDuration(headers);
  }

  static String? _serverErrorMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      for (final key in ['msg', 'message', 'error_description', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }

  Options _authOptions(SupabaseAuthSession session) {
    return Options(headers: {'Authorization': 'Bearer ${session.accessToken}'});
  }

  static Map<String, dynamic> _mapBody(Object? body) {
    return body is Map<String, dynamic> ? body : const <String, dynamic>{};
  }

  Options _mergeAuthOptions(SupabaseAuthSession session, Options? options) {
    final headers = <String, dynamic>{
      ...?options?.headers,
      'Authorization': 'Bearer ${session.accessToken}',
    };
    return (options ?? Options()).copyWith(headers: headers);
  }

  static void logDioException(DioException error, {Object? payload}) {
    final request = error.requestOptions;
    debugPrint('[Supabase HTTP] method: ${request.method}');
    debugPrint('[Supabase HTTP] url: ${request.uri}');
    debugPrint('[Supabase HTTP] status: ${error.response?.statusCode}');
    debugPrint(
      '[Supabase HTTP] response.data: '
      '${_safeResponseData(request.path, error.response?.data)}',
    );
    debugPrint(
      '[Supabase HTTP] response.headers: ${error.response?.headers.map}',
    );
    debugPrint(
      '[Supabase HTTP] request.headers: ${_safeHeaders(request.headers)}',
    );
    debugPrint(
      '[Supabase HTTP] payload.keys: ${_payloadKeys(payload ?? request.data)}',
    );
  }

  static Map<String, Object?> _safeHeaders(Map<String, dynamic> headers) {
    return {
      for (final entry in headers.entries)
        entry.key: _isSecretHeader(entry.key) ? '<redacted>' : entry.value,
    };
  }

  static bool _isSecretHeader(String key) {
    final normalized = key.toLowerCase();
    return normalized == 'apikey' || normalized == 'authorization';
  }

  static Object _safeResponseData(String path, Object? data) {
    if (!path.startsWith('/auth/v1/')) {
      return data ?? '<empty>';
    }

    if (data is Map<String, dynamic>) {
      return {
        'keys': data.keys.toList(),
        'error_code': data['code'] ?? data['error_code'],
        'message': _serverErrorMessage(data),
        'user_present': data['user'] is Map,
        'session_present': data['session'] is Map,
      };
    }

    return data == null ? '<empty>' : data.runtimeType.toString();
  }

  static Object _payloadKeys(Object? payload) {
    if (payload == null) {
      return const [];
    }
    if (payload is Map) {
      return payload.keys.map((key) => key.toString()).toList();
    }
    if (payload is List<int>) {
      return 'bytes(length=${payload.length})';
    }
    if (payload is List) {
      final keys = <String>{};
      for (final item in payload) {
        if (item is Map) {
          keys.addAll(item.keys.map((key) => key.toString()));
        }
      }
      return keys.isEmpty ? 'list(length=${payload.length})' : keys.toList();
    }
    return payload.runtimeType.toString();
  }

  void _ensureConfigured() {
    if (!isConfigured) {
      throw const SupabaseNotConfiguredException();
    }
  }
}

class SupabaseAuthSession {
  const SupabaseAuthSession({
    required this.userId,
    required this.email,
    required this.accessToken,
    required this.displayName,
    required this.isAnonymous,
    required this.projectUrl,
  });

  final String userId;
  final String? email;
  final String accessToken;
  final String displayName;
  final bool isAnonymous;
  final String projectUrl;

  bool get hasAuthenticatedSession =>
      accessToken.isNotEmpty && userId.isNotEmpty;

  bool get isEmailConfirmationPending {
    return accessToken.isEmpty &&
        userId.isNotEmpty &&
        email != null &&
        email!.isNotEmpty &&
        !isAnonymous;
  }

  factory SupabaseAuthSession.fromJson(
    Map<String, dynamic> json, {
    required String projectUrl,
  }) {
    final session = json['session'] is Map<String, dynamic>
        ? json['session'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final user = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : session['user'] is Map<String, dynamic>
        ? session['user'] as Map<String, dynamic>
        : json['id'] is String
        ? json
        : const <String, dynamic>{};
    final metadata = user['user_metadata'] is Map<String, dynamic>
        ? user['user_metadata'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final email = user['email'] as String?;
    final displayName =
        metadata['display_name'] as String? ??
        metadata['name'] as String? ??
        email ??
        'Supabase Collector';

    return SupabaseAuthSession(
      userId: user['id'] as String? ?? '',
      email: email,
      accessToken:
          json['access_token'] as String? ??
          session['access_token'] as String? ??
          '',
      displayName: displayName,
      isAnonymous: email == null || email.isEmpty,
      projectUrl: projectUrl,
    );
  }

  factory SupabaseAuthSession.fromJsonString(String value) {
    final decoded = Uri.splitQueryString(value);
    return SupabaseAuthSession(
      userId: decoded['userId'] ?? '',
      email: decoded['email']?.isEmpty == true ? null : decoded['email'],
      accessToken: decoded['accessToken'] ?? '',
      displayName: decoded['displayName'] ?? 'Supabase Collector',
      isAnonymous: decoded['isAnonymous'] == 'true',
      projectUrl: decoded['projectUrl'] ?? '',
    );
  }

  String toJsonString() {
    return Uri(
      queryParameters: {
        'userId': userId,
        'email': email ?? '',
        'accessToken': accessToken,
        'displayName': displayName,
        'isAnonymous': isAnonymous.toString(),
        'projectUrl': projectUrl,
      },
    ).query;
  }
}

class SupabaseNotConfiguredException implements Exception {
  const SupabaseNotConfiguredException();

  @override
  String toString() {
    return 'Supabase is not configured. Provide SUPABASE_URL, '
        'SUPABASE_ANON_KEY, and SUPABASE_ENABLED=true.';
  }
}

class SupabaseAuthException implements Exception {
  const SupabaseAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class SupabaseConfirmationRateLimitedException implements Exception {
  const SupabaseConfirmationRateLimitedException({
    required this.cooldown,
    required this.cooldownSource,
  });

  static const message =
      'Too many confirmation requests. Please wait before trying again.';

  final Duration cooldown;
  final String cooldownSource;

  @override
  String toString() => message;
}

class SupabasePasswordResetRateLimitedException implements Exception {
  const SupabasePasswordResetRateLimitedException({
    required this.cooldown,
    required this.cooldownSource,
  });

  static const message =
      'Too many reset requests. Please wait a few minutes and try again.';

  final Duration cooldown;
  final String cooldownSource;

  @override
  String toString() => message;
}

class SupabaseSessionExpiredException implements Exception {
  const SupabaseSessionExpiredException();

  static const message = 'Session expired. Please sign in again.';

  @override
  String toString() => message;
}

class SupabaseEmailConfirmationRequiredException implements Exception {
  const SupabaseEmailConfirmationRequiredException();

  static const message =
      'Check your email to confirm your account, then sign in.';

  @override
  String toString() => message;
}

class SupabaseEmailConfirmationSentException implements Exception {
  const SupabaseEmailConfirmationSentException();

  static const message =
      'Check your email to confirm your account, then sign in.';

  @override
  String toString() => message;
}
